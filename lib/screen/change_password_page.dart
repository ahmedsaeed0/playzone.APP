import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Password strength
  double _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _newPassCtrl.addListener(_evalStrength);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ─── Password Strength ────────────────────────────────────────────────────
  void _evalStrength() {
    final p = _newPassCtrl.text;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.25;

    String label;
    Color color;
    if (s <= 0.25) {
      label = 'ضعيفة';
      color = Colors.red;
    } else if (s <= 0.5) {
      label = 'مقبولة';
      color = Colors.orange;
    } else if (s <= 0.75) {
      label = 'جيدة';
      color = Colors.amber;
    } else {
      label = 'قوية';
      color = Colors.green;
    }

    setState(() {
      _strength = s;
      _strengthLabel = p.isEmpty ? '' : label;
      _strengthColor = p.isEmpty ? Colors.transparent : color;
    });
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final current = _currentPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _snack("يرجى ملء جميع الحقول");
      return;
    }
    if (newPass.length < 8) {
      _snack("كلمة المرور يجب أن تكون 8 أحرف على الأقل");
      return;
    }
    if (newPass != confirm) {
      _snack("كلمتا المرور غير متطابقتين");
      return;
    }
    if (current == newPass) {
      _snack("كلمة المرور الجديدة يجب أن تختلف عن الحالية");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.changePassword(
        currentPassword: current,
        newPassword: newPass,
        newPasswordConfirmation: confirm,
      );
      _snack("تم تغيير كلمة المرور بنجاح", ok: true);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ??
          e.response?.data['error'] ??
          "فشل تغيير كلمة المرور";
      _snack(msg);
    } catch (_) {
      _snack("حدث خطأ، حاول مرة أخرى");
    }
    setState(() => _isLoading = false);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppTheme.primaryDark : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static double _fs(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);
  static double _sz(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);

  Widget _passField(
    BuildContext ctx,
    TextEditingController ctrl,
    String hint,
    bool obscure,
    VoidCallback toggleObscure, {
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(
          color: AppTheme.textPrimary, fontSize: _fs(ctx, 14)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: AppTheme.primary, size: _sz(ctx, 20)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.textSecondary,
            size: _sz(ctx, 20),
          ),
          onPressed: toggleObscure,
        ),
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
        title: Text(
          "تغيير كلمة المرور",
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: _fs(context, 18)),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ─── Header ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ─── Form ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: _buildForm(context),
              ),
            ),

            // ─── Tips ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildTips(context),
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
    final heroH = (mq.size.height * 0.22).clamp(160.0, 220.0);
    final iconSz = (mq.size.width * 0.18).clamp(60.0, 85.0);

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
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -15,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.only(top: mq.padding.top),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSz,
                    height: iconSz,
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
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: _sz(ctx, 30),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "تغيير كلمة المرور",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: _fs(ctx, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "أنشئ كلمة مرور قوية لحماية حسابك",
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

  // ─── Form ─────────────────────────────────────────────────────────────────
  Widget _buildForm(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "بيانات كلمة المرور",
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: _fs(ctx, 17),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(_sz(ctx, 16)),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current password
              _passField(
                ctx,
                _currentPassCtrl,
                "كلمة المرور الحالية",
                _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 14),

              // Divider
              Divider(height: 1, color: AppTheme.borderColor),
              const SizedBox(height: 14),

              // New password
              _passField(
                ctx,
                _newPassCtrl,
                "كلمة المرور الجديدة",
                _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (_) {},
              ),

              // Strength indicator
              if (_strengthLabel.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _strength,
                          backgroundColor: AppTheme.borderColor,
                          valueColor:
                              AlwaysStoppedAnimation(_strengthColor),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _strengthLabel,
                      style: TextStyle(
                          color: _strengthColor,
                          fontSize: _fs(ctx, 12),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Confirm new password
              _passField(
                ctx,
                _confirmPassCtrl,
                "تأكيد كلمة المرور الجديدة",
                _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: _sz(ctx, 50),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor:
                        AppTheme.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "حفظ كلمة المرور",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _fs(ctx, 15),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Tips ─────────────────────────────────────────────────────────────────
  Widget _buildTips(BuildContext ctx) {
    final tips = [
      (Icons.check_circle_outline_rounded, "8 أحرف على الأقل"),
      (Icons.check_circle_outline_rounded, "حرف كبير وحرف صغير"),
      (Icons.check_circle_outline_rounded, "رقم واحد على الأقل"),
      (Icons.check_circle_outline_rounded, "رمز خاص مثل @، #، \$"),
    ];

    return Container(
      padding: EdgeInsets.all(_sz(ctx, 16)),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_outlined,
                color: AppTheme.primaryLight, size: 18),
            const SizedBox(width: 8),
            Text(
              "نصائح لكلمة مرور قوية",
              style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: _fs(ctx, 14),
                  fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(t.$1,
                      color: AppTheme.primary.withOpacity(0.7), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    t.$2,
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(ctx, 13)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}