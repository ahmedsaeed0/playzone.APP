import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../route/app_routes.dart';
import '../services/auth_service.dart';

// ─── PlayZone Brand Colors ────────────────────────────────────────────────────
const _primary = Color(0xFFD80B12);
const _primaryDark = Color(0xFF9A0008);
const _primaryLight = Color(0xFFFF3B42);
const _bgDark = Color(0xFF0A0000);
const _bgCard = Color(0xFF1A0505);
const _bgField = Color(0xFF110202);
const _textPrimary = Color(0xFFFFFFFF);
const _textMuted = Color(0xFF9E7070);
const _border = Color(0xFF3A1010);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _emailFocus = false;
  bool _passFocus = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);

    _logoCtrl.forward();
    Future.delayed(
      const Duration(milliseconds: 200),
          () => _slideCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _logoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ─── Login API ────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnack("يرجى تعبئة جميع الحقول");
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _loading = true);

    try {
      final dio = Dio();
      final response = await dio.post(
        "https://playzoone.com/api/login",
        data: {"email": _emailCtrl.text.trim(), "password": _passCtrl.text},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final token = response.data["token"] as String;
      await AuthService.saveToken(token);
      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSnack("أهلاً بك! تم تسجيل الدخول بنجاح ✓", isError: false);

        await Future.delayed(const Duration(milliseconds: 600));

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.support,
              (route) => false,
        );
      }
    } on DioException catch (e) {
      String msg = "فشل تسجيل الدخول";
      if (e.response?.statusCode == 401 || e.response?.statusCode == 422) {
        msg = "البريد الإلكتروني أو كلمة المرور غير صحيحة";
      } else if (e.type == DioExceptionType.connectionTimeout) {
        msg = "انتهت مهلة الاتصال، تحقق من الإنترنت";
      }
      _showSnack(msg);
    } catch (_) {
      _showSnack("حدث خطأ غير متوقع");
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? _primary : _primaryDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // ── decorative glow ──────────────────────────────────────
            Positioned(
              top: -100,
              left: -100,
              child: _glowCircle(350, _primary.withOpacity(0.06)),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: _glowCircle(280, _primaryDark.withOpacity(0.08)),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 70),

                    // ── Logo ────────────────────────────────────────
                    ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_primaryDark, _primary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.5),
                                  blurRadius: 35,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Image.asset(
                                'assets/images/img.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "PlayZone",
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "سجّل دخولك للمتابعة",
                            style: TextStyle(color: _textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Form ────────────────────────────────────────
                    SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          // Email
                          _focusField(
                            isFocused: _emailFocus,
                            onFocusChange:
                                (f) => setState(() => _emailFocus = f),
                            child: TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 15,
                              ),
                              decoration: _fieldDecoration(
                                hint: "البريد الإلكتروني",
                                icon: Icons.alternate_email_rounded,
                                isFocused: _emailFocus,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password
                          _focusField(
                            isFocused: _passFocus,
                            onFocusChange:
                                (f) => setState(() => _passFocus = f),
                            child: TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 15,
                              ),
                              decoration: _fieldDecoration(
                                hint: "كلمة المرور",
                                icon: Icons.lock_outline_rounded,
                                isFocused: _passFocus,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _textMuted,
                                    size: 20,
                                  ),
                                  onPressed:
                                      () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Login button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient:
                              _loading
                                  ? const LinearGradient(
                                colors: [_border, _border],
                              )
                                  : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_primaryDark, _primary],
                              ),
                              boxShadow:
                              _loading
                                  ? []
                                  : [
                                BoxShadow(
                                  color: _primary.withOpacity(0.45),
                                  blurRadius: 22,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loading ? null : _login,
                              child:
                              _loading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : const Text(
                                "تسجيل الدخول",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // TextButton(
                          //   onPressed: () => Navigator.pop(context),
                          //   child: const Text(
                          //     "متابعة بدون تسجيل دخول",
                          //     style: TextStyle(
                          //       color: _textMuted,
                          //       fontSize: 13,
                          //       decoration: TextDecoration.underline,
                          //       decorationColor: _border,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "PlayZone © 2025",
                      style: TextStyle(color: _border, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _glowCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _focusField({
    required bool isFocused,
    required ValueChanged<bool> onFocusChange,
    required Widget child,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow:
          isFocused
              ? [
            BoxShadow(
              color: _primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: child,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required bool isFocused,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
      prefixIcon: Icon(
        icon,
        color: isFocused ? _primaryLight : _textMuted,
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: _bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }
}
