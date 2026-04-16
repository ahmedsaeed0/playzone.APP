import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController controller = PageController();
  int currentPage = 0;
  late AnimationController _animController;

  List<Map<String, dynamic>> pages = [
    {
      "title": "كل ما تحتاجه في عالم الألعاب",
      "text":
      "متجر متخصص يوفر كل ما يتعلق بالألعاب على جميع المنصات "
          "\u2067PlayStation\u2069 و "
          "\u2067Xbox\u2069 و "
          "\u2067PC\u2069. "
          "نمنحك خيارات واسعة وأسعار تنافسية.",
      "image": "assets/onboarding/img.png",
      "icon": Icons.card_giftcard_rounded,
      "color": Color(0xFFFF3B30),
    },
    {
      "title": "شحن فوري وخدمات بلا حدود",
      "text":
      "لا تضيع وقتك في البحث! نوفر جميع بطاقات الألعاب، الاشتراكات، وخدمات المشاهدة في مكان واحد، بأسعار لا تُنافس. تفعيل فوري بعد الدفع مع ضمان كامل للثقة والأمان.",
      "image": "assets/onboarding/gift2.webp",
      "icon": Icons.flash_on_rounded,
      "color": Color(0xFFFF9500),
    },
    {
      "title": "أمان عالي وموثوقية كاملة",
      "text":
      "معايير حماية قوية لمدفوعاتك، دعم سريع، وتقييمات ممتازة من آلاف العملاء. تسوق وأنت مطمئن",
      "image": "assets/onboarding/img_1.png",
      "icon": Icons.verified_user_rounded,
      "color": Color(0xFF34C759),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("seenOnboarding", true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A0909),
              Color(0xFF250F0F),
              Color(0xFF090909),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // تحديد نوع الجهاز
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final isTablet = width >= 600;
              final isLargeTablet = width >= 900; // iPad Pro
              final orientation = MediaQuery.of(context).orientation;
              final isLandscape = orientation == Orientation.landscape;

              // حساب الأحجام بشكل ديناميكي
              double iconSize;
              double iconInnerSize;
              double imageHeight;
              double titleFontSize;
              double textFontSize;
              double buttonHeight;
              double horizontalPadding;
              double maxContentWidth;

              if (isLargeTablet) {
                // iPad Pro & Large Tablets
                iconSize = isLandscape ? 140.0 : 160.0;
                iconInnerSize = isLandscape ? 70.0 : 80.0;
                imageHeight = isLandscape ? 250.0 : 300.0;
                titleFontSize = isLandscape ? 34.0 : 38.0;
                textFontSize = isLandscape ? 19.0 : 21.0;
                buttonHeight = 64.0;
                horizontalPadding = isLandscape ? 80.0 : 60.0;
                maxContentWidth = isLandscape ? 700.0 : 600.0;
              } else if (isTablet) {
                // iPad Mini & Standard Tablets
                iconSize = isLandscape ? 120.0 : 140.0;
                iconInnerSize = isLandscape ? 60.0 : 70.0;
                imageHeight = isLandscape ? 220.0 : 260.0;
                titleFontSize = isLandscape ? 30.0 : 34.0;
                textFontSize = isLandscape ? 18.0 : 20.0;
                buttonHeight = 60.0;
                horizontalPadding = isLandscape ? 60.0 : 50.0;
                maxContentWidth = isLandscape ? 600.0 : 500.0;
              } else {
                // Phones
                final isSmallScreen = height < 700;
                final isVerySmallScreen = height < 600;

                iconSize = isVerySmallScreen ? 80.0 : (isSmallScreen ? 100.0 : 120.0);
                iconInnerSize = isVerySmallScreen ? 40.0 : (isSmallScreen ? 50.0 : 60.0);
                imageHeight = isVerySmallScreen ? 140.0 : (isSmallScreen ? 170.0 : 200.0);
                titleFontSize = isVerySmallScreen ? 22.0 : (isSmallScreen ? 25.0 : 28.0);
                textFontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 15.5 : 17.0);
                buttonHeight = isVerySmallScreen ? 50.0 : 56.0;
                horizontalPadding = width < 360 ? 20.0 : 30.0;
                maxContentWidth = width;
              }

              return Column(
                children: [
                  // Header مع زر التخطي
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isTablet ? 15 : 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo أو اسم التطبيق
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/img.png',
                                width: isTablet ? 36 : 28,
                                height: isTablet ? 36 : 28,
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Flexible(
                                child: Text(
                                  'PlayZone',
                                  style: TextStyle(
                                    fontSize: isTablet ? 28 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // زر تخطي محسّن
                        TextButton(
                          onPressed: finishOnboarding,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 20 : 16,
                              vertical: isTablet ? 12 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "تخطي",
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 30 : 20),

                  // محتوى الصفحات
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: maxContentWidth,
                        ),
                        child: PageView.builder(
                          controller: controller,
                          itemCount: pages.length,
                          onPageChanged: (index) {
                            setState(() => currentPage = index);
                            _animController.reset();
                            _animController.forward();
                          },
                          itemBuilder: (_, index) {
                            return FadeTransition(
                              opacity: _animController,
                              child: SingleChildScrollView(
                                physics: BouncingScrollPhysics(),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: isTablet ? 40 : 20),

                                      // أيقونة مع خلفية دائرية
                                      Container(
                                        width: iconSize,
                                        height: iconSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              pages[index]["color"]
                                                  .withOpacity(0.3),
                                              pages[index]["color"]
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: pages[index]["color"]
                                                  .withOpacity(0.3),
                                              blurRadius: isTablet ? 50 : 40,
                                              spreadRadius: isTablet ? 8 : 5,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          pages[index]["icon"],
                                          size: iconInnerSize,
                                          color: pages[index]["color"],
                                        ),
                                      ),

                                      SizedBox(
                                        height: isTablet
                                            ? (isLandscape ? 40 : 60)
                                            : 50,
                                      ),

                                      // الصورة
                                      Container(
                                        height: imageHeight,
                                        constraints: BoxConstraints(
                                          maxWidth: isTablet
                                              ? maxContentWidth * 0.7
                                              : width * 0.8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(25),
                                          child: Image.asset(
                                            pages[index]["image"]!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),

                                      SizedBox(
                                        height: isTablet
                                            ? (isLandscape ? 40 : 60)
                                            : 50,
                                      ),

                                      // العنوان
                                      Text(
                                        pages[index]["title"]!,
                                        style: TextStyle(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      SizedBox(height: isTablet ? 24 : 16),

                                      // الوصف
                                      Text(
                                        pages[index]["text"]!,
                                        style: TextStyle(
                                          fontSize: textFontSize,
                                          color: Colors.white60,
                                          height: 1.6,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      SizedBox(height: isTablet ? 40 : 30),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // المؤشر
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 25 : 20,
                    ),
                    child: SmoothPageIndicator(
                      controller: controller,
                      count: pages.length,
                      effect: ExpandingDotsEffect(
                        expansionFactor: 4,
                        dotWidth: isTablet ? 10 : 8,
                        dotHeight: isTablet ? 10 : 8,
                        spacing: isTablet ? 8 : 6,
                        activeDotColor: Colors.red,
                        dotColor: Colors.white24,
                      ),
                    ),
                  ),

                  // زر التالي / ابدأ
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : double.infinity,
                        ),
                        width: double.infinity,
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: currentPage == pages.length - 1
                                ? [Color(0xFFFF3B30), Color(0xFFFF6B5A)]
                                : [Color(0xFFFF9500), Color(0xFFFFB340)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: currentPage == pages.length - 1
                                  ? Color(0xFFFF3B30).withOpacity(0.4)
                                  : Color(0xFFFF9500).withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (currentPage == pages.length - 1) {
                              await finishOnboarding();
                            } else {
                              controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentPage == pages.length - 1
                                    ? "ابدأ الآن"
                                    : "التالي",
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Icon(
                                currentPage == pages.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: isTablet ? 24 : 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 50 : 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}