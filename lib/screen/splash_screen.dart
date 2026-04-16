import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:playzone/screen/support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'webview_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  HeadlessInAppWebView? _headlessWebView;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF490808),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _preloadWebsite();
    _initializeApp();
  }

  // يحمل الموقع في الخلفية أثناء الـ splash لتعبئة الـ cache
  Future<void> _preloadWebsite() async {
    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("https://playzone-ksa.com")),
      initialSettings: InAppWebViewSettings(
        cacheEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        javaScriptEnabled: true,
      ),
    );
    await _headlessWebView!.run();
  }

  Future<String> _getHomeScreen() async {
    try {
      final response = await Dio().get(
        'https://playzoone.com/api/app-config',
        options: Options(
          headers: {"Accept": "application/json"},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.data['show_screen'] ?? 'support';
    } catch (e) {
      return 'support';
    }
  }

  Future<void> _initializeApp() async {
    await _requestPermissionsOnce();

    final results = await Future.wait([
      _getHomeScreen(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    final homeScreen = results[0] as String;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => homeScreen == 'webview'
              ? const WebViewPage()
              : const SupportPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
          barrierColor: const Color(0xFF250F0F),
          opaque: true,
        ),
      );
    }
  }

  Future<void> _requestPermissionsOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsRequested = prefs.getBool('permissions_requested') ?? false;

    if (!permissionsRequested) {
      await Permission.camera.request();
      await Permission.photos.request();
      await Permission.storage.request();
      await prefs.setBool('permissions_requested', true);
    }
  }

  @override
  void dispose() {
    _headlessWebView?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A0909),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A0909),
              Color(0xFF250F0F),
              Color(0xFF490808),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.asset('assets/images/img.png',
                            width: 150, height: 150),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PlayZone',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
