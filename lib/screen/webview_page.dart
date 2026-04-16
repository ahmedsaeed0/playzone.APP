import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? controller;
  bool isConnected = true;
  bool isLoading = false;
  bool isCheckingConnection = true;
  bool showConnectionLostBar = false;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    checkInitialConnection();
    listenToConnectivity();
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> checkInitialConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      isConnected = !connectivityResult.contains(ConnectivityResult.none);
      isCheckingConnection = false;
    });
  }

  void listenToConnectivity() {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasConnected = isConnected;
      final nowConnected = !results.contains(ConnectivityResult.none);

      setState(() {
        isConnected = nowConnected;

        if (wasConnected && !nowConnected) {
          showConnectionLostBar = true;
        }

        if (!wasConnected && nowConnected) {
          showConnectionLostBar = false;
        }
      });

      if (!wasConnected && nowConnected && controller != null) {
        controller!.reload();
        setState(() {
          isLoading = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'تم استعادة الاتصال بنجاح',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> retryConnection() async {
    setState(() {
      isCheckingConnection = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await checkInitialConnection();

    if (isConnected && controller != null) {
      controller!.reload();
      setState(() {
        isLoading = true;
      });
    }
  }

  Future<List<String>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.map((file) => file.path!).toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Color(0xFF670A0A),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [

            // WebView - يظهر بس بعد انتهاء التحقق
            if (isConnected && !isCheckingConnection)
              InAppWebView(
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  transparentBackground: true,
                  useHybridComposition: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  mediaPlaybackRequiresUserGesture: false,
                  javaScriptCanOpenWindowsAutomatically: true,
                  cacheEnabled: true,
                  cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  supportZoom: true,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  minimumFontSize: isTablet ? 14 : 12,
                ),
                initialUrlRequest: URLRequest(
                  url: WebUri("https://playzone-ksa.com"),
                ),
                onWebViewCreated: (c) async {
                  controller = c;
                  controller!.addJavaScriptHandler(
                    handlerName: 'fileChooser',
                    callback: (args) async {
                      final files = await pickFiles();
                      return files;
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    isLoading = false;
                  });

                  await controller.evaluateJavascript(
                    source: """
                    (function() {
                      var originalClick = HTMLInputElement.prototype.click;
                      HTMLInputElement.prototype.click = function() {
                        if (this.type === 'file') {
                          window.flutter_inappwebview.callHandler('fileChooser').then(function(files) {
                            console.log('Files selected:', files);
                          });
                        } else {
                          originalClick.call(this);
                        }
                      };
                    })();
                  """,
                  );
                },
                onReceivedError: (controller, request, error) {
                  setState(() {
                    isLoading = false;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url!;
                  final url = uri.toString();

                  final externalSchemes = [
                    'tel:',
                    'mailto:',
                    'whatsapp:',
                    'fb:',
                    'instagram:',
                    'twitter:',
                    'tg:',
                    'intent:',
                  ];

                  final externalDomains = [
                    'facebook.com',
                    'twitter.com',
                    'instagram.com',
                    'youtube.com',
                    'maps.google.com',
                    'play.google.com',
                  ];

                  if (externalSchemes.any((scheme) => url.startsWith(scheme))) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (externalDomains.any((domain) => url.contains(domain))) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (url.endsWith('.pdf')) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
              ),

            // شاشة عدم الاتصال
            if (!isConnected && !isCheckingConnection)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6A0909), Color(0xFF250F0F), Color(0xFF490808)],
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 48.0 : 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: isTablet ? 140 : 100,
                            color: Colors.redAccent[400],
                          ),
                          SizedBox(height: isTablet ? 32 : 24),
                          Text(
                            'لا يوجد اتصال بالإنترنت',
                            style: TextStyle(
                              fontSize: isTablet ? 32 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isTablet ? 48 : 40),
                          SizedBox(
                            width: isTablet ? 300 : double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: retryConnection,
                              icon: Icon(
                                Icons.refresh_rounded,
                                size: isTablet ? 28 : 24,
                              ),
                              label: Text(
                                'إعادة المحاولة',
                                style: TextStyle(fontSize: isTablet ? 20 : 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 40 : 32,
                                  vertical: isTablet ? 20 : 16,
                                ),
                                textStyle: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading فوق الـ WebView بعد ما يبدأ يحمل
            if (isLoading && isConnected && !isCheckingConnection)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6A0909), Color(0xFF250F0F), Color(0xFF490808)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset('assets/images/img.png',
                            width: isTablet ? 150 : 150,
                            height: isTablet ? 150 : 150),
                      ),
                      SizedBox(height: isTablet ? 32 : 24),
                      SizedBox(
                        width: isTablet ? 50 : 36,
                        height: isTablet ? 50 : 36,
                        child: CircularProgressIndicator(
                          strokeWidth: isTablet ? 4 : 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // شاشة التحقق من الاتصال - تظهر في البداية
            if (isCheckingConnection)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6A0909), Color(0xFF250F0F), Color(0xFF490808)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset('assets/images/img.png',
                            width: isTablet ? 120 : 90,
                            height: isTablet ? 120 : 90),
                      ),
                      SizedBox(height: isTablet ? 32 : 24),
                      SizedBox(
                        width: isTablet ? 50 : 36,
                        height: isTablet ? 50 : 36,
                        child: CircularProgressIndicator(
                          strokeWidth: isTablet ? 4 : 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // شريط انقطاع الاتصال
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: showConnectionLostBar ? 0 : -120,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                    horizontal: isTablet ? 24 : 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF3B30), Color(0xFFFF6B5A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: isTablet ? 32 : 24,
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'انقطع الاتصال بالإنترنت',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'يرجى التحقق من الاتصال',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: isTablet ? 16 : 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 8),
                        TextButton(
                          onPressed: retryConnection,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 10 : 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 16 : 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
