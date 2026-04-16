import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFFD80B12);
  static const Color primaryDark   = Color(0xFF9A0008);
  static const Color primaryLight  = Color(0xFFFF3B42);
  static const Color bgDark        = Color(0xFF0A0000);
  static const Color bgCard        = Color(0xFF1A0505);
  static const Color bgField       = Color(0xFF110202);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E7070);
  static const Color borderColor   = Color(0xFF3A1010);
  static const Color success       = Color(0xFF25D366);

  // ─── Responsive Breakpoints ────────────────────────────────────────────────
  // phone  < 600
  // tablet 600 – 1024
  // desktop > 1024
  static bool isPhone(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 &&
          MediaQuery.of(ctx).size.width < 1024;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1024;

  /// Horizontal padding that grows with screen width
  static double hPad(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= 1024) return w * 0.28;
    if (w >= 600)  return w * 0.15;
    return 24;
  }

  /// Card max-width for centred layouts on wide screens
  static double cardMaxW(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= 1024) return 520;
    if (w >= 600)  return 560;
    return double.infinity;
  }

  /// Scaled font size helper
  static double fs(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= 1024) return base * 1.18;
    if (w >= 600)  return base * 1.08;
    return base;
  }

  /// Scaled icon / avatar size helper
  static double sz(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    if (w >= 1024) return base * 1.3;
    if (w >= 600)  return base * 1.15;
    return base;
  }

  // ─── Theme ────────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
      surface: bgCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
  );
}