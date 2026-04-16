import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadNotifications();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getNotifications();
      setState(() {
        _notifications = data['notifications'] ?? [];
        _unreadCount = data['unread_count'] ?? 0;
      });
    } catch (_) {
      _snack("فشل تحميل الإشعارات");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markRead(int id, int index) async {
    try {
      await AuthService.markNotificationRead(id);
      setState(() {
        _notifications[index]['is_read'] = true;
        if (_unreadCount > 0) _unreadCount--;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await AuthService.markAllNotificationsRead();
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
        _unreadCount = 0;
      });
      _snack("تم تعليم الكل كمقروء", ok: true);
    } catch (_) {
      _snack("حدث خطأ، حاول مرة أخرى");
    }
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

  static double _fs(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);
  static double _sz(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("الإشعارات",
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: _fs(context, 18))),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_unreadCount',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _fs(context, 11),
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text("قراءة الكل",
                  style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: _fs(context, 13))),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primary))
          : FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ─── Empty ───────────────────────────────────────────
            if (_notifications.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.bgCard,
                        border: Border.all(
                            color: AppTheme.borderColor, width: 1),
                      ),
                      child: const Icon(
                          Icons.notifications_off_outlined,
                          color: AppTheme.textSecondary,
                          size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text("لا توجد إشعارات بعد",
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: _fs(context, 16),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("ستظهر هنا جميع إشعاراتك",
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: _fs(context, 13))),
                  ]),
                ),
              )
            else ...[
              // ─── Stats ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildStats(context),
                ),
              ),

              // ─── List ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text("كل الإشعارات",
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: _fs(context, 17),
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildCard(context, _notifications[i], i),
                    childCount: _notifications.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final heroH = (mq.size.height * 0.20).clamp(150.0, 200.0);
    final iconSz = (mq.size.width * 0.16).clamp(50.0, 74.0);

    return Container(
      height: heroH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0000), AppTheme.bgDark],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: mq.padding.top),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: iconSz, height: iconSz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2)
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_rounded,
                      color: Colors.white, size: iconSz * 0.46),
                  if (_unreadCount > 0)
                    Positioned(
                      top: iconSz * 0.1,
                      right: iconSz * 0.1,
                      child: Container(
                        width: iconSz * 0.28,
                        height: iconSz * 0.28,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$_unreadCount',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _fs(ctx, 9),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text("الإشعارات",
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(ctx, 19),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(
              _unreadCount > 0
                  ? 'لديك $_unreadCount إشعار غير مقروء'
                  : 'جميع الإشعارات مقروءة',
              style: TextStyle(
                  color: _unreadCount > 0
                      ? AppTheme.primaryLight
                      : AppTheme.textSecondary,
                  fontSize: _fs(ctx, 12)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext ctx) {
    final total = _notifications.length;
    final unread = _unreadCount;
    final read = total - unread;

    return Row(children: [
      _statCard(ctx,
          label: 'الكل', value: '$total', color: AppTheme.primary,
          icon: Icons.notifications_outlined),
      const SizedBox(width: 10),
      _statCard(ctx,
          label: 'غير مقروء', value: '$unread', color: Colors.orange,
          icon: Icons.mark_email_unread_outlined),
      const SizedBox(width: 10),
      _statCard(ctx,
          label: 'مقروء', value: '$read', color: Colors.green,
          icon: Icons.done_all_rounded),
    ]);
  }

  Widget _statCard(BuildContext ctx, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: _sz(ctx, 14), horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: _sz(ctx, 20)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: _fs(ctx, 18),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: _fs(ctx, 10)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ─── Notification Card ────────────────────────────────────────────────────
  Widget _buildCard(BuildContext ctx, dynamic notif, int index) {
    final isRead = notif['is_read'] == true || notif['is_read'] == 1;
    final title = notif['title'] ?? '';
    final body = notif['body'] ?? '';
    final createdAt = _formatDate(notif['created_at']);

    return GestureDetector(
      onTap: () {
        if (!isRead) _markRead(notif['id'], index);
        _showDetail(ctx, notif);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(_sz(ctx, 14)),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppTheme.borderColor
                : AppTheme.primary.withOpacity(0.4),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Row(children: [
          // أيقونة
          Container(
            width: _sz(ctx, 44),
            height: _sz(ctx, 44),
            decoration: BoxDecoration(
              color: (isRead ? AppTheme.borderColor : AppTheme.primary)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isRead
                  ? Icons.notifications_outlined
                  : Icons.notifications_active_rounded,
              color: isRead ? AppTheme.textSecondary : AppTheme.primary,
              size: _sz(ctx, 22),
            ),
          ),
          SizedBox(width: _sz(ctx, 12)),
          // المحتوى
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: _fs(ctx, 14),
                            fontWeight: FontWeight.w700)),
                  ),
                  if (!isRead)
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.primary),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(ctx, 12),
                        height: 1.4)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.access_time_rounded,
                      color: AppTheme.textSecondary, size: _sz(ctx, 12)),
                  const SizedBox(width: 4),
                  Text(createdAt,
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: _fs(ctx, 11))),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Detail Sheet ─────────────────────────────────────────────────────────
  void _showDetail(BuildContext ctx, dynamic notif) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(notif['title'] ?? '',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: _fs(ctx, 16),
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 16),
            Divider(color: AppTheme.borderColor, height: 1),
            const SizedBox(height: 16),
            Text(notif['body'] ?? '',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: _fs(ctx, 14),
                    height: 1.7)),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.access_time_rounded,
                  color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(_formatDate(notif['created_at']),
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: _fs(ctx, 12))),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Utils ────────────────────────────────────────────────────────────────
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw ?? '—';
    }
  }
}