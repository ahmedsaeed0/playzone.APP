import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:playzone/screen/support.dart';
// import 'package:playzone/support.dart';
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
  bool isLoading = true;
  bool isCheckingConnection = false;
  bool showConnectionLostBar = false;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  @override
  void initState() {
    super.initState();
    checkInitialConnection();
    listenToConnectivity();
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> checkInitialConnection() async {
    setState(() {
      isCheckingConnection = true;
    });

    final connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      isConnected = !connectivityResult.contains(ConnectivityResult.none);
      isCheckingConnection = false;
      if (isConnected) {
        isLoading = false;
      }
    });
  }

  void listenToConnectivity() {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> results) {
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
      },
    );
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
    // الحصول على معلومات الجهاز
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // WebView
            if (isConnected)
              InAppWebView(
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useHybridComposition: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  mediaPlaybackRequiresUserGesture: false,
                  javaScriptCanOpenWindowsAutomatically: true,
                  // تحسينات للأداء على جميع الأجهزة
                  cacheEnabled: true,
                  supportZoom: true,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  // تحسين العرض على الشاشات الكبيرة
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  // تحسين الخطوط
                  minimumFontSize: isTablet ? 14 : 12,
                ),
                initialUrlRequest: URLRequest(
                  url: WebUri("https://playzoone.com"),
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

                  await controller.evaluateJavascript(source: """
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
                  """);
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
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (externalDomains.any((domain) => url.contains(domain))) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (url.endsWith('.pdf')) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
              ),

            // شاشة عدم الاتصال - محسّنة للأجهزة المختلفة
            if (!isConnected && !isCheckingConnection)
              Container(
                color: Colors.white,
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
                              color: Colors.red[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              color: Colors.grey[600],
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
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                ),
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

            // Loading indicator - محسّن
            if (isLoading && isConnected)
              Container(
                color: Colors.white.withOpacity(0.9),
                child: Center(
                  child: SizedBox(
                    width: isTablet ? 60 : 40,
                    height: isTablet ? 60 : 40,
                    child: CircularProgressIndicator(
                      strokeWidth: isTablet ? 5 : 4,
                    ),
                  ),
                ),
              ),

            // Loading أثناء التحقق - محسّن
            if (isCheckingConnection)
              Container(
                color: Colors.white.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: isTablet ? 60 : 40,
                        height: isTablet ? 60 : 40,
                        child: CircularProgressIndicator(
                          strokeWidth: isTablet ? 5 : 4,
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                      Text(
                        'جاري التحقق من الاتصال...',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // شريط انقطاع الاتصال - محسّن لجميع الأجهزة
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
                        color: Colors.red.withOpacity(0.3),
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
                                  color: Colors.white.withOpacity(0.9),
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
                            backgroundColor: Colors.white.withOpacity(0.2),
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
          
          Positioned(
  bottom: 25,
  right: 20,
  child: FloatingActionButton(
    backgroundColor: Colors.green,
    child: const Icon(Icons.support_agent, color: Colors.white),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SupportPage(),
        ),
      );
    },
  ),
),
          ],
        ),
      ),
    );
  }
}