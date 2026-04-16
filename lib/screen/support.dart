import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playzone/screen/profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/SupportiService.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';
import 'ticket_chat_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with TickerProviderStateMixin {
  bool isLoggedIn = false;
  bool isLoadingTickets = false;
  List<dynamic> tickets = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _fabCtrl;
  late Animation<double> _fabAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);

    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _fabCtrl.forward());
    _checkLogin();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    final s = await AuthService.isLoggedIn();
    setState(() => isLoggedIn = s);
    if (s) _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => isLoadingTickets = true);
    try {
      final d = await SupportApiService.getTickets();
      setState(() => tickets = d);
    } catch (_) {
      _snack("فشل تحميل التذاكر");
    }
    setState(() => isLoadingTickets = false);
  }


  void _openChat(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => TicketChatPage(ticket: ticket),
        transitionsBuilder:
            (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child, 
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _loadTickets());
  }



  void _newTicketSheet() {
    final subCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder: (ctx, inner) {
              final bottom = MediaQuery.of(ctx).viewInsets.bottom;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _cardMaxW(ctx)),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          "تذكرة دعم جديدة",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: _fs(ctx, 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _textField(subCtrl, "الموضوع", Icons.subject),
                        const SizedBox(height: 14),
                        _textField(
                          msgCtrl,
                          "وصف المشكلة",
                          Icons.message_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: _sz(ctx, 52),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                sending
                                    ? null
                                    : () async {
                                      if (subCtrl.text.isEmpty ||
                                          msgCtrl.text.isEmpty)
                                        return;
                                      inner(() => sending = true);
                                      try {
                                        await SupportApiService.createTicket(
                                          subject: subCtrl.text,
                                          message: msgCtrl.text,
                                        );
                                        if (mounted) {
                                          Navigator.pop(ctx);
                                          _snack(
                                            "تم إرسال التذكرة بنجاح ✓",
                                            ok: true,
                                          );
                                          _loadTickets();
                                        }
                                      } catch (_) {
                                        _snack("فشل إرسال التذكرة");
                                        inner(() => sending = false);
                                      }
                                    },
                            child:
                                sending
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      "إرسال التذكرة",
                                      style: TextStyle(
                                        fontSize: _fs(ctx, 16),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _startChat() {
    if (isLoggedIn) {
      _newTicketSheet();
      return;
    }
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _cardMaxW(context)),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      "ابدأ الدردشة مع الدعم",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: _fs(context, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "سجّل دخولك لتتبع تذاكرك ",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(context, 13),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sheetBtn(
                      label: "تسجيل الدخول",
                      icon: Icons.login_rounded,
                      primary: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/login',
                        ).then((_) => _checkLogin());
                      },
                    ),

                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppTheme.primaryDark : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteDialog() {
    final reasonCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppTheme.bgCard,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "حذف الحساب",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: _fs(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "سيتم حذف حسابك بشكل نهائي ولا يمكن التراجع.",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: _fs(context, 13),
                  ),
                ),
                const SizedBox(height: 16),
                _textField(
                  reasonCtrl,
                  "اكتب سبب الحذف...",
                  Icons.edit_note,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(context, 14),
                  ),
                  decoration: InputDecoration(
                    hintText: "كلمة المرور للتأكيد",
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppTheme.primary,
                      size: _sz(context, 20),
                    ),
                    filled: true,
                    fillColor: AppTheme.bgField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "إلغاء",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (passCtrl.text.isEmpty) {
                    _snack("أدخل كلمة المرور للتأكيد");
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    await SupportApiService.requestAccountDeletion(
                      password: passCtrl.text,
                      reason: reasonCtrl.text,
                    );
                    _snack("تم إرسال طلب حذف الحساب", ok: true);
                  } on DioException catch (e) {
                    final msg =
                        e.response?.data['message'] ?? "فشل إرسال الطلب";
                    _snack(msg);
                  } catch (_) {
                    _snack("فشل إرسال الطلب، حاول مرة أخرى");
                  }
                },
                child: const Text(
                  "تأكيد الحذف",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
  // ─── Responsive helpers (لا تعتمد على AppTheme فقط) ──────────────────────

  /// font size متجاوب: يتمدد بين الشاشات الصغيرة والكبيرة
  static double _fs(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    // نسبة بين 0.85 (شاشة 320px) و 1.15 (شاشة 430px+)
    final scale = (w / 390).clamp(0.85, 1.15);
    return base * scale;
  }

  /// حجم عام متجاوب
  static double _sz(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    final scale = (w / 390).clamp(0.85, 1.15);
    return base * scale;
  }

  /// أقصى عرض للكارد (للأجهزة اللوحية والشاشات الكبيرة)
  static double _cardMaxW(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w > 600 ? 520 : w;
  }

  /// padding أفقي متجاوب
  static double _hPad(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w > 600) return 40;
    if (w > 400) return 20;
    return 16;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          "الدعم الفني",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: _fs(context, 18),
          ),
        ),
        centerTitle: true,
        leading: isLoggedIn
            ? IconButton(
          icon: const Icon(
            Icons.person,
            color: AppTheme.primaryLight,
          ),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        )
            : null,
        actions: [
          if (isLoggedIn) ...[
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: _loadTickets,
            ),
          ],
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Hero
            SliverToBoxAdapter(child: _hero(context)),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _hPad(context),
                  24,
                  _hPad(context),
                  0,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _quickBtn(
                          context,
                          icon: Icons.confirmation_number_outlined,
                          label: "تذاكري",
                          color: AppTheme.primary,
                          onTap: isLoggedIn
                              ? _loadTickets
                              : () => _snack("سجّل دخولك أولاً لعرض التذاكر"),
                        ),
                        const SizedBox(width: 12),
                        _quickBtn(
                          context,
                          icon: Icons.chat_bubble_outline_rounded,
                          label: "دردشة",
                          color: AppTheme.primaryLight,
                          onTap: _startChat,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _quickBtn(
                          context,
                          icon: Icons.help_outline,
                          label: "مركز المساعدة",
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pushNamed(context, '/help');
                          },
                        ),
                        const SizedBox(width: 12),
                        _quickBtn(
                          context,
                          icon: Icons.settings_suggest,
                          label: "حالة النظام",
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(context, '/status');
                          },
                        ),
                        const SizedBox(width: 12),
                        _quickBtn(
                          context,
                          icon: Icons.campaign_outlined,
                          label: "الإعلانات",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, '/announcements');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tickets section
            if (isLoggedIn) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _hPad(context),
                    32,
                    _hPad(context),
                    12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "تذاكر الدعم",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: _fs(context, 17),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (isLoadingTickets)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (tickets.isEmpty && !isLoadingTickets)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: _hPad(context)),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            color: AppTheme.textSecondary,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "لا توجد تذاكر بعد",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: _fs(context, 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: _hPad(context)),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ticketCard(context, tickets[i]),
                      childCount: tickets.length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.5),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
            label: Text(
              "تذكرة جديدة",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _fs(context, 14),
              ),
            ),
            onPressed: _startChat,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─── Hero - متجاوب تماماً ─────────────────────────────────────────────────
  Widget _hero(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final topPad = mq.padding.top; // ارتفاع status bar الحقيقي
    final screenH = mq.size.height;
    final screenW = mq.size.width;

    // أفاتار متجاوب: بين 60 و 90 بناءً على الشاشة
    final avatarSz = (screenW * 0.19).clamp(60.0, 90.0);

    // ارتفاع الـ hero: 25% من الشاشة، لكن لا يقل عن 190 ولا يزيد عن 260
    final heroH = (screenH * 0.25).clamp(190.0, 260.0);

    return Container(
      height: heroH,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A0000), AppTheme.bgDark],
        ),
      ),
      child: Stack(
        children: [
          // دائرة خلفية يمين
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.07),
              ),
            ),
          ),
          // دائرة خلفية يسار
          Positioned(
            bottom: 8,
            left: -25,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),

          // المحتوى - padding يدوي بدلاً من SafeArea لتجنب overflow
          Padding(
            padding: EdgeInsets.only(top: topPad),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة الدعم
                  Container(
                    width: avatarSz,
                    height: avatarSz,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.45),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: avatarSz * 0.48,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenH * 0.012),
                  Text(
                    "كيف يمكننا مساعدتك؟",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: _fs(ctx, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "فريقنا جاهز للمساعدة على مدار الساعة",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: _fs(ctx, 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ticket Card ──────────────────────────────────────────────────────────
  Widget _ticketCard(BuildContext ctx, dynamic ticket) {
    final isOpen = (ticket['status'] ?? 'open') == 'open';
    final msgs = ticket['messages'] as List? ?? [];
    final lastMsg = msgs.isNotEmpty ? msgs.last['message'] ?? '' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openChat(Map<String, dynamic>.from(ticket)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(_sz(ctx, 16)),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isOpen
                      ? AppTheme.primary.withOpacity(0.35)
                      : AppTheme.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // أيقونة الحالة
              Container(
                width: _sz(ctx, 46),
                height: _sz(ctx, 46),
                decoration: BoxDecoration(
                  color: (isOpen ? AppTheme.primary : AppTheme.borderColor)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOpen
                      ? Icons.pending_outlined
                      : Icons.check_circle_outline_rounded,
                  color: isOpen ? AppTheme.primary : AppTheme.textSecondary,
                  size: _sz(ctx, 24),
                ),
              ),
              SizedBox(width: _sz(ctx, 12)),

              // الموضوع + آخر رسالة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['subject'] ?? 'تذكرة دعم',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: _fs(ctx, 14),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(ctx, 12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: _sz(ctx, 12),
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${msgs.length} رسائل",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: _fs(ctx, 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // الحالة + سهم
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isOpen ? AppTheme.primary : AppTheme.borderColor)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? "مفتوحة" : "مغلقة",
                      style: TextStyle(
                        color:
                            isOpen
                                ? AppTheme.primaryLight
                                : AppTheme.textSecondary,
                        fontSize: _fs(ctx, 11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                    size: _sz(ctx, 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _quickBtn(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: _sz(ctx, 14)),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: _sz(ctx, 24)),
              SizedBox(height: _sz(ctx, 6)),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: _fs(ctx, 11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetBtn({
    required String label,
    required IconData icon,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _sz(context, 54),
        decoration: BoxDecoration(
          gradient:
              primary
                  ? const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                  : null,
          color: primary ? null : AppTheme.bgField,
          borderRadius: BorderRadius.circular(14),
          border:
              primary
                  ? null
                  : Border.all(color: AppTheme.borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : AppTheme.textSecondary,
              size: _sz(context, 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: _fs(context, 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(context, 14)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: _sz(context, 20)),
        filled: true,
        fillColor: AppTheme.bgField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
