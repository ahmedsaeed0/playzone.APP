import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'تحديثات', 'عروض', 'صيانة', 'أخبار'];

  List<_Announcement> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const String _baseUrl = 'https://playzoone.com/api';

  List<_Announcement> get _filtered {
    if (_selectedFilter == 'الكل') return _announcements;
    return _announcements.where((a) => a.tag == _selectedFilter).toList();
  }

  int get _unreadCount => _announcements.where((a) => !a.isRead).length;

  static double _fs(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);

  static double _sz(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.get('$_baseUrl/announcements');

      final rawList = (response.data['announcements'] ?? []) as List;

      final items = rawList
          .map((e) => _Announcement.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _announcements = items;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            e.response?.data?['message']?.toString() ?? 'فشل تحميل الإعلانات';
      });
      debugPrint('Announcements Dio error: ${e.message}');
      debugPrint('Announcements status: ${e.response?.statusCode}');
      debugPrint('Announcements data: ${e.response?.data}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ غير متوقع';
      });
      debugPrint('Announcements unknown error: $e');
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      _announcements = _announcements
          .map((a) => a.copyWith(isRead: true))
          .toList();
    });

    // لو عندك endpoint لاحقًا:
    // await Dio().post('$_baseUrl/announcements/read-all', ...);
  }

  void _openAnnouncement(_Announcement ann) {
    final idx = _announcements.indexWhere((a) => a.id == ann.id);
    if (idx != -1) {
      setState(() {
        _announcements[idx] = ann.copyWith(isRead: true);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ann.tagColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ann.tag,
                            style: TextStyle(
                              color: ann.tagColor,
                              fontSize: _fs(context, 12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ann.date,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: _fs(context, 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ann.title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: _fs(context, 20),
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppTheme.borderColor, height: 1),
                    const SizedBox(height: 16),
                    Text(
                      ann.body,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(context, 14),
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: ann.tagColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ann.icon, color: ann.tagColor, size: 36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الإعلانات',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: _fs(context, 18),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _fs(context, 11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadAnnouncements,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
          ),
          // لو داير ترجع زر قراءة الكل بعدين:
          // if (_unreadCount > 0)
          //   TextButton(
          //     onPressed: _markAllRead,
          //     child: Text(
          //       'قراءة الكل',
          //       style: TextStyle(
          //         color: AppTheme.primaryLight,
          //         fontSize: _fs(context, 13),
          //       ),
          //     ),
          //   ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  itemCount: _filters.length,
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final isSelected = f == _selectedFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: _fs(context, 13),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  '${filtered.length} إعلان',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: _fs(context, 13),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.textSecondary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: _fs(context, 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAnnouncements,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          color: AppTheme.textSecondary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد إعلانات في هذا القسم',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: _fs(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildCard(context, filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                ),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final heroH = (mq.size.height * 0.20).clamp(150.0, 200.0);
    final iconSz = (mq.size.width * 0.16).clamp(50.0, 74.0);

    return Container(
      height: heroH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0000), AppTheme.bgDark],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: mq.padding.top),
        child: Center(
          child: Column(
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
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: iconSz * 0.46,
                ),
              ),
              Text(
                'إعلانات PlayZone',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: _fs(ctx, 19),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'آخر الأخبار والتحديثات والعروض',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: _fs(ctx, 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext ctx, _Announcement ann) {
    return GestureDetector(
      onTap: () => _openAnnouncement(ann),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(_sz(ctx, 16)),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ann.isRead
                ? AppTheme.borderColor
                : ann.tagColor.withOpacity(0.4),
            width: ann.isRead ? 1 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: _sz(ctx, 40),
                  height: _sz(ctx, 40),
                  decoration: BoxDecoration(
                    color: ann.tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    ann.icon,
                    color: ann.tagColor,
                    size: _sz(ctx, 20),
                  ),
                ),
                SizedBox(width: _sz(ctx, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ann.tagColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ann.tag,
                              style: TextStyle(
                                color: ann.tagColor,
                                fontSize: _fs(ctx, 10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (ann.isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.push_pin_rounded,
                              color: AppTheme.primaryLight,
                              size: _sz(ctx, 13),
                            ),
                          ],
                          const Spacer(),
                          if (!ann.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ann.tagColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ann.date,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: _fs(ctx, 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: _sz(ctx, 10)),
            Text(
              ann.title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: _fs(ctx, 14),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ann.body.length > 100
                  ? '${ann.body.substring(0, 100)}...'
                  : ann.body,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: _fs(ctx, 12),
                height: 1.5,
              ),
            ),
            SizedBox(height: _sz(ctx, 10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'اقرأ المزيد',
                  style: TextStyle(
                    color: ann.tagColor,
                    fontSize: _fs(ctx, 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_left_rounded,
                  color: ann.tagColor,
                  size: _sz(ctx, 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Announcement {
  final String id;
  final String title;
  final String body;
  final String tag;
  final Color tagColor;
  final String date;
  final bool isPinned;
  final bool isRead;
  final IconData icon;

  const _Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.tag,
    required this.tagColor,
    required this.date,
    required this.isPinned,
    required this.isRead,
    required this.icon,
  });

  factory _Announcement.fromJson(Map<String, dynamic> json) {
    final tag = (json['tag'] ?? 'أخبار').toString();

    return _Announcement(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      tag: tag,
      tagColor: _tagColor(tag),
      date: (json['date'] ?? json['created_at'] ?? '').toString(),
      isPinned: _toBool(json['is_pinned']),
      isRead: _toBool(json['is_read']),
      icon: _tagIcon(tag),
    );
  }

  _Announcement copyWith({bool? isRead}) => _Announcement(
    id: id,
    title: title,
    body: body,
    tag: tag,
    tagColor: tagColor,
    date: date,
    isPinned: isPinned,
    isRead: isRead ?? this.isRead,
    icon: icon,
  );

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static Color _tagColor(String tag) {
    switch (tag) {
      case 'تحديثات':
        return const Color(0xFF1E88E5);
      case 'عروض':
        return const Color(0xFFF57C00);
      case 'صيانة':
        return const Color(0xFF8E24AA);
      case 'أخبار':
        return const Color(0xFF43A047);
      default:
        return AppTheme.primary;
    }
  }

  static IconData _tagIcon(String tag) {
    switch (tag) {
      case 'تحديثات':
        return Icons.system_update_rounded;
      case 'عروض':
        return Icons.local_offer_rounded;
      case 'صيانة':
        return Icons.build_circle_outlined;
      case 'أخبار':
        return Icons.campaign_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }
}