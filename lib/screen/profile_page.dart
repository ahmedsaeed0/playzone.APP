import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/SupportiService.dart';
import '../app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getProfile();
      setState(() => _userData = data);
    } catch (_) {
      _snack("فشل تحميل البيانات");
    }
    setState(() => _isLoading = false);
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

  // ─── Logout ───────────────────────────────────────────────────────────────
  void _logoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded,
                color: AppTheme.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Text("تسجيل الخروج",
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: _fs(context, 17),
                  fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          "هل أنت متأكد من تسجيل الخروج؟",
          style: TextStyle(
              color: AppTheme.textSecondary, fontSize: _fs(context, 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء",
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false);
              }
            },
            child: const Text("خروج",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Delete Account ───────────────────────────────────────────────────────
  void _deleteDialog() {
    final reasonCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text("حذف الحساب",
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(context, 17),
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "سيتم حذف حسابك بشكل نهائي ولا يمكن التراجع.",
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: _fs(context, 13)),
            ),
            const SizedBox(height: 16),
            _textField(reasonCtrl, "سبب الحذف (اختياري)",
                Icons.edit_note, maxLines: 3),
            const SizedBox(height: 12),
            _textField(passCtrl, "كلمة المرور للتأكيد",
                Icons.lock_outline, obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء",
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
                _snack(e.response?.data['message'] ?? "فشل إرسال الطلب");
              } catch (_) {
                _snack("فشل إرسال الطلب، حاول مرة أخرى");
              }
            },
            child: const Text("تأكيد الحذف",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static double _fs(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);
  static double _sz(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);

  Widget _textField(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
        int maxLines = 1,
        bool obscure = false,
      }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      obscureText: obscure,
      style: TextStyle(
          color: AppTheme.textPrimary, fontSize: _fs(context, 14)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon:
        Icon(icon, color: AppTheme.primary, size: _sz(context, 20)),
        filled: true,
        fillColor: AppTheme.bgField,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: AppTheme.borderColor, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: AppTheme.primary, width: 1.5)),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("الملف الشخصي",
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: _fs(context, 18))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary),
            onPressed: _loadProfile,
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
            // ─── Header / Avatar ──────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ─── Info Cards ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: _buildInfoSection(context),
              ),
            ),

            // ─── Stats ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildStats(context),
              ),
            ),

            // ─── Actions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildActions(context),
              ),
            ),

            // ─── Danger Zone ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildDangerZone(context),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final heroH = (mq.size.height * 0.28).clamp(200.0, 280.0);
    final avatarSz = (mq.size.width * 0.22).clamp(70.0, 100.0);

    final name = _userData['name'] ?? _userData['username'] ?? 'المستخدم';
    final email = _userData['email'] ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Container(
      height: heroH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A0000), AppTheme.bgDark],
        ),
      ),
      child: Stack(
        children: [
          // دوائر زخرفية
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: -15,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),
          // المحتوى
          Padding(
            padding: EdgeInsets.only(top: mq.padding.top),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: avatarSz,
                    height: avatarSz,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _fs(ctx, 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: _fs(ctx, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(ctx, 13),
                      ),
                    ),
                  ],
                  // Badge عضوية
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: AppTheme.primaryLight, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _userData['role'] ?? "عضو",
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: _fs(ctx, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  // ─── Info Section ─────────────────────────────────────────────────────────
  Widget _buildInfoSection(BuildContext ctx) {
    final fields = <_InfoField>[
      if ((_userData['name'] ?? '').isNotEmpty)
        _InfoField(icon: Icons.person_outline_rounded,
            label: 'الاسم', value: _userData['name']),
      if ((_userData['username'] ?? '').isNotEmpty)
        _InfoField(icon: Icons.alternate_email_rounded,
            label: 'اسم المستخدم', value: _userData['username']),
      if ((_userData['email'] ?? '').isNotEmpty)
        _InfoField(icon: Icons.email_outlined,
            label: 'البريد الإلكتروني', value: _userData['email']),
      if ((_userData['phone'] ?? '').isNotEmpty)
        _InfoField(icon: Icons.phone_outlined,
            label: 'رقم الهاتف', value: _userData['phone']),
      if ((_userData['created_at'] ?? '').isNotEmpty)
        _InfoField(icon: Icons.calendar_today_outlined,
            label: 'تاريخ التسجيل',
            value: _formatDate(_userData['created_at'])),
    ];

    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("المعلومات الشخصية",
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: _fs(ctx, 17),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Column(
            children: fields.asMap().entries.map((e) {
              final f = e.value;
              final isLast = e.key == fields.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(_sz(ctx, 14)),
                    child: Row(
                      children: [
                        Container(
                          width: _sz(ctx, 36),
                          height: _sz(ctx, 36),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(f.icon,
                              color: AppTheme.primary, size: _sz(ctx, 18)),
                        ),
                        SizedBox(width: _sz(ctx, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.label,
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: _fs(ctx, 11))),
                              const SizedBox(height: 2),
                              Text(f.value,
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: _fs(ctx, 14),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: _sz(ctx, 62),
                        color: AppTheme.borderColor),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext ctx) {
    // اعرض الإحصائيات فقط لو موجودة في بيانات API
    final ticketsCount = _userData['tickets_count']?.toString() ?? '—';
    final ordersCount = _userData['orders_count']?.toString() ?? '—';
    final joinDays = _userData['days_since_joined']?.toString() ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("إحصائياتي",
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: _fs(ctx, 17),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(ctx, icon: Icons.confirmation_number_outlined,
                label: 'تذاكر الدعم', value: ticketsCount,
                color: AppTheme.primary),
            const SizedBox(width: 10),
            _statCard(ctx, icon: Icons.shopping_bag_outlined,
                label: 'الطلبات', value: ordersCount,
                color: Colors.orange),
            const SizedBox(width: 10),
            _statCard(ctx, icon: Icons.calendar_month_outlined,
                label: 'أيام العضوية', value: joinDays,
                color: Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _statCard(BuildContext ctx, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: _sz(ctx, 16), horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: _sz(ctx, 22)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: _fs(ctx, 18),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: _fs(ctx, 10)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("الإعدادات",
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: _fs(ctx, 17),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Column(
            children: [
              _actionTile(ctx,
                  icon: Icons.notifications_outlined,
                  label: "الإشعارات",
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/notifications')),

              Divider(height: 1, indent: 56, color: AppTheme.borderColor),
              _actionTile(ctx,
                  icon: Icons.lock_outline_rounded,
                  label: "تغيير كلمة المرور",
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/change-password')),
              Divider(height: 1, indent: 56, color: AppTheme.borderColor),
              _actionTile(ctx,
                  icon: Icons.help_outline_rounded,
                  label: "مركز المساعدة",
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/help')),
              Divider(height: 1, indent: 56, color: AppTheme.borderColor),
              _actionTile(ctx,
                  icon: Icons.logout_rounded,
                  label: "تسجيل الخروج",
                  color: AppTheme.primary,
                  onTap: _logoutDialog),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile(BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(_sz(ctx, 14)),
        child: Row(
          children: [
            Container(
              width: _sz(ctx, 36),
              height: _sz(ctx, 36),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: _sz(ctx, 18)),
            ),
            SizedBox(width: _sz(ctx, 12)),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: _fs(ctx, 14),
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_left_rounded,
                color: AppTheme.textSecondary, size: _sz(ctx, 20)),
          ],
        ),
      ),
    );
  }

  // ─── Danger Zone ──────────────────────────────────────────────────────────
  Widget _buildDangerZone(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.all(_sz(ctx, 16)),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text("منطقة الخطر",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: _fs(ctx, 14),
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
            "حذف الحساب إجراء نهائي ولا يمكن التراجع عنه. ستُفقد جميع بياناتك.",
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: _fs(ctx, 12),
                height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteDialog,
              icon: const Icon(Icons.delete_forever_rounded,
                  color: Colors.redAccent, size: 18),
              label: Text("حذف حسابي",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: _fs(ctx, 14),
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: _sz(ctx, 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Utils ────────────────────────────────────────────────────────────────
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _InfoField {
  final IconData icon;
  final String label;
  final String value;
  const _InfoField(
      {required this.icon, required this.label, required this.value});
}