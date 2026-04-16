import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../services/SupportiService.dart';
import '../app_theme.dart';

class TicketChatPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const TicketChatPage({super.key, required this.ticket});

  @override
  State<TicketChatPage> createState() => _TicketChatPageState();
}

class _TicketChatPageState extends State<TicketChatPage> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();

  List<dynamic> messages = [];
  File?  _pickedFile;
  bool   sending = false;
  int?   currentUserId;

  @override
  void initState() {
    super.initState();
    messages = List<dynamic>.from(widget.ticket['messages'] ?? []);
    _loadUserId();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(jump: true));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadUserId() {
    final userMsg = messages.firstWhere(
            (m) => m['is_admin'] == 0, orElse: () => null);
    if (userMsg != null) setState(() => currentUserId = userMsg['user_id']);
  }

  // ─── Pick image from camera / gallery ─────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final xf = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1280);
    if (xf != null) setState(() => _pickedFile = File(xf.path));
    Navigator.pop(context); // close bottom sheet
  }

  // ─── Pick any file ────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedFile = File(result.files.single.path!));
    }
    Navigator.pop(context);
  }

  // ─── Attachment picker sheet ──────────────────────────────────────────────
  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          Text("إرفاق ملف",
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fs(context, 17),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _attachOption(
              icon: Icons.camera_alt_rounded,
              label: "كاميرا",
              color: AppTheme.primary,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            _attachOption(
              icon: Icons.photo_library_rounded,
              label: "معرض الصور",
              color: const Color(0xFF9C63FF),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            _attachOption(
              icon: Icons.attach_file_rounded,
              label: "ملف",
              color: AppTheme.success,
              onTap: _pickFile,
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fs(context, 12))),
      ]),
    );
  }

  // ─── Send ──────────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if ((text.isEmpty && _pickedFile == null) || sending) return;

    HapticFeedback.lightImpact();
    setState(() => sending = true);

    // Optimistic UI
    final tempMsg = {
      'id': -1,
      'ticket_id': widget.ticket['id'],
      'user_id': currentUserId,
      'is_admin': 0,
      'message': text,
      'attachment': _pickedFile?.path, // local path مؤقت
      '_isLocal': true,
      'created_at': DateTime.now().toIso8601String(),
    };
    final fileToSend = _pickedFile;
    setState(() {
      messages.add(tempMsg);
      _msgCtrl.clear();
      _pickedFile = null;
    });
    _scrollToBottom();

    try {
      await SupportApiService.sendMessage(
        ticketId: widget.ticket['id'] as int,
        message: text.isNotEmpty ? text : null,
        attachment: fileToSend,
      );
      await _refreshMessages();
    } catch (_) {
      setState(() => messages.remove(tempMsg));
      _msgCtrl.text = text;
      setState(() => _pickedFile = fileToSend);
      _snack("فشل إرسال الرسالة");
    }

    setState(() => sending = false);
  }

  Future<void> _refreshMessages() async {
    try {
      final tickets = await SupportApiService.getTickets();
      final updated = tickets.firstWhere(
              (t) => t['id'] == widget.ticket['id'],
          orElse: () => null);
      if (updated != null && mounted) {
        setState(() =>
        messages = List<dynamic>.from(updated['messages'] ?? []));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (jump) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        } else {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final subject = widget.ticket['subject'] ?? 'تذكرة دعم';
    final isOpen  = (widget.ticket['status'] ?? 'open') == 'open';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0505),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subject,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fs(context, 15),
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? AppTheme.success : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(isOpen ? "مفتوحة" : "مغلقة",
                style: TextStyle(
                    color: isOpen
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    fontSize: AppTheme.fs(context, 11))),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary, size: 20),
            onPressed: _refreshMessages,
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: messages.isEmpty
              ? _emptyState()
              : ListView.builder(
            controller: _scrollCtrl,
            padding: EdgeInsets.fromLTRB(
                AppTheme.hPad(context), 16,
                AppTheme.hPad(context), 8),
            itemCount: messages.length,
            itemBuilder: (_, i) => _bubble(context, messages[i]),
          ),
        ),

        // Preview ملف مختار
        if (_pickedFile != null) _filePreview(),

        // Input bar
        _inputBar(context, isOpen),
      ]),
    );
  }

  // ─── File preview strip ────────────────────────────────────────────────────
  Widget _filePreview() {
    final isImage = _isImageFile(_pickedFile!.path);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Row(children: [
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_pickedFile!,
                width: 48, height: 48, fit: BoxFit.cover),
          )
        else
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: AppTheme.primary, size: 26),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            p.basename(_pickedFile!.path),
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fs(context, 13)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppTheme.textSecondary, size: 20),
          onPressed: () => setState(() => _pickedFile = null),
        ),
      ]),
    );
  }

  // ─── Input Bar ─────────────────────────────────────────────────────────────
  Widget _inputBar(BuildContext ctx, bool isOpen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppTheme.hPad(ctx), 10,
          AppTheme.hPad(ctx),
          MediaQuery.of(ctx).viewInsets.bottom + 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0505),
        border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Row(children: [
        // Attach button
        if (isOpen)
          GestureDetector(
            onTap: _showAttachSheet,
            child: Container(
              width: AppTheme.sz(ctx, 42),
              height: AppTheme.sz(ctx, 42),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.borderColor, width: 1),
              ),
              child: Icon(Icons.attach_file_rounded,
                  color: AppTheme.textSecondary,
                  size: AppTheme.sz(ctx, 20)),
            ),
          ),

        // Text field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: TextField(
              controller: _msgCtrl,
              enabled: isOpen,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fs(ctx, 14)),
              decoration: InputDecoration(
                hintText: isOpen ? "اكتب رسالتك..." : "التذكرة مغلقة",
                hintStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fs(ctx, 14)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.sz(ctx, 16),
                    vertical: AppTheme.sz(ctx, 12)),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: AppTheme.sz(ctx, 46),
          height: AppTheme.sz(ctx, 46),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isOpen
                ? const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
                : const LinearGradient(
                colors: [AppTheme.borderColor, AppTheme.borderColor]),
            boxShadow: isOpen
                ? [BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 10, offset: const Offset(0, 3))]
                : [],
          ),
          child: IconButton(
            onPressed: isOpen && !sending ? _sendMessage : null,
            icon: sending
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Icon(Icons.send_rounded,
                color: Colors.white,
                size: AppTheme.sz(ctx, 20)),
          ),
        ),
      ]),
    );
  }

  // ─── Message Bubble ────────────────────────────────────────────────────────
  Widget _bubble(BuildContext ctx, dynamic msg) {
    final isAdmin  = msg['is_admin'] == 1;
    final text     = msg['message'] ?? '';
    final attach   = msg['attachment'];
    final isLocal  = msg['_isLocal'] == true;
    final timeStr  = _formatTime(msg['created_at']);
    final isTemp   = msg['id'] == -1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Container(
              width: AppTheme.sz(ctx, 30),
              height: AppTheme.sz(ctx, 30),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary]),
              ),
              child: Icon(Icons.support_agent_rounded,
                  size: AppTheme.sz(ctx, 15), color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(ctx).size.width * 0.72),
              padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.sz(ctx, 12),
                  vertical: AppTheme.sz(ctx, 9)),
              decoration: BoxDecoration(
                color: isAdmin ? AppTheme.bgCard : AppTheme.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isAdmin ? 4 : 18),
                  bottomRight: Radius.circular(isAdmin ? 18 : 4),
                ),
                border: isAdmin
                    ? Border.all(color: AppTheme.borderColor, width: 1)
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("الدعم الفني",
                          style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: AppTheme.fs(ctx, 11),
                              fontWeight: FontWeight.bold)),
                    ),

                  // Attachment
                  if (attach != null && attach.toString().isNotEmpty)
                    _attachmentWidget(ctx, attach.toString(), isLocal),

                  // Text
                  if (text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                          top: attach != null ? 6 : 0),
                      child: Text(text,
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fs(ctx, 14),
                              height: 1.4)),
                    ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr,
                          style: TextStyle(
                              color: AppTheme.textSecondary
                                  .withOpacity(0.7),
                              fontSize: AppTheme.fs(ctx, 10))),
                      if (!isAdmin && !isTemp) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: AppTheme.sz(ctx, 13),
                            color: AppTheme.primaryLight),
                      ],
                      if (isTemp) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: AppTheme.sz(ctx, 10),
                          height: AppTheme.sz(ctx, 10),
                          child: const CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Attachment widget inside bubble ──────────────────────────────────────
  Widget _attachmentWidget(BuildContext ctx, String path, bool isLocal) {
    final isImage = _isImageFile(path);

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isLocal
            ? Image.file(File(path),
            width: 200, height: 160, fit: BoxFit.cover)
            : Image.network(
          SupportApiService.fileUrl(path),
          width: 200, height: 160, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _fileChip(ctx, path),
        ),
      );
    }

    return _fileChip(ctx, path);
  }

  Widget _fileChip(BuildContext ctx, String path) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            color: AppTheme.primary,
            size: AppTheme.sz(ctx, 18),
          ),
          const SizedBox(width: 6),

          Expanded(
            child: Text(
              p.basename(path),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fs(ctx, 12),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.chat_bubble_outline_rounded,
          size: 52, color: AppTheme.borderColor),
      const SizedBox(height: 12),
      Text("لا توجد رسائل بعد",
          style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fs(context, 14))),
    ]),
  );

  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }
}