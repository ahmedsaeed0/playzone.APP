import 'package:flutter/material.dart';
import '../screen/announcements_page.dart';
import '../screen/change_password_page.dart';
import '../screen/help_center_page.dart';
import '../screen/login_page.dart';
import '../screen/notifications_page.dart';
import '../screen/profile_page.dart';
import '../screen/support.dart';
import '../screen/system_status_page.dart';


class AppRoutes {
  // ─── Route Names ─────────────────────────────────────────────────────────────
  static const String support = '/support';
  static const String login   = '/login';

  // ─── Route Map ───────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
    support : (_) => const SupportPage(),
    login   : (_) => const LoginPage(),
    '/help':          (context) => const HelpCenterPage(),          // ← أضف
    '/status':        (context) => const SystemStatusPage(),        // ← أضف
    '/announcements': (context) => const AnnouncementsPage(),
    '/profile': (context) => const ProfilePage(),
    '/notifications': (context) => const NotificationsPage(),
    '/change-password': (context) => const ChangePasswordPage(),



  };
}