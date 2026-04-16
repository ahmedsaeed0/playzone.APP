import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:playzone/route/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/splash_screen.dart';
import 'screen/onboarding_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? seenOnboarding;

  @override
  void initState() {
    super.initState();
    checkOnboardingSeen();
    initFirebase();
  }

  void checkOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool value = prefs.getBool("seenOnboarding") ?? false;
    setState(() {
      seenOnboarding = value;
    });
  }

  Future<void> initFirebase() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // طلب الإذن
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print("🔔 Permission: ${settings.authorizationStatus}");

      final prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString("token");
      print("👤 userToken: $userToken");

      if (userToken == null) {
        print("⚠️ لا يوجد userToken - المستخدم غير مسجل");
        return;
      }

      // انتظر APNS token على iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        print("🍎 iOS - انتظار APNS token...");
        String? apnsToken;
        int retries = 0;

        while (apnsToken == null && retries < 5) {
          apnsToken = await messaging.getAPNSToken();
          print("🍎 APNS attempt ${retries + 1}: $apnsToken");
          if (apnsToken == null) {
            await Future.delayed(const Duration(seconds: 2));
            retries++;
          }
        }

        if (apnsToken == null) {
          print("❌ APNS token فشل بعد 5 محاولات");
          return;
        }
        print("✅ APNS token جاهز: $apnsToken");
      }

      // اطلب FCM token
      print("📱 جاري طلب FCM token...");
      String? token = await messaging.getToken();
      print("📱 FCM TOKEN: $token");

      if (token == null) {
        print("❌ FCM token رجع null");
        return;
      }

      // أرسل للسيرفر
      print("📤 إرسال للسيرفر...");
      final response = await Dio().post(
        "https://playzoone.com/api/save-token",
        data: {
          "token": token,
          "device": Platform.isIOS ? "ios" : "android",  // ← أضف
        },        options: Options(
          headers: {
            "Authorization": "Bearer $userToken",
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );
      print("✅ Server status: ${response.statusCode}");
      print("✅ Server response: ${response.data}");

    } catch (e, stackTrace) {
      print("❌ Firebase Error: $e");
      print("📋 Stack: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (seenOnboarding == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6A0909), Color(0xFF250F0F), Color(0xFF490808)],
              ),
            ),
            child: Center(
              child: Image.asset('assets/images/img.png', width: 120, height: 120),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlayZone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routes: AppRoutes.routes,
      // home: const OnboardingScreen(),
      home: seenOnboarding == true
          ? const SplashScreen()
          : const OnboardingScreen(),
    );
  }
}