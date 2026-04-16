import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});
  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<_FaqCategory> _categories = [
    _FaqCategory(
      title: 'الحساب والأمان',
      icon: Icons.shield_outlined,
      color: Color(0xFFE53935),
      items: [
        _FaqItem(q: 'كيف أغيّر كلمة المرور؟', a: 'اذهب إلى الإعدادات ← الحساب ← تغيير كلمة المرور، أدخل كلمة المرور الحالية ثم الجديدة واضغط حفظ.'),
        _FaqItem(q: 'كيف أفعّل المصادقة الثنائية؟', a: 'من إعدادات الأمان يمكنك تفعيل المصادقة الثنائية عبر رقم الهاتف أو تطبيق المصادقة.'),
        _FaqItem(q: 'هل يمكنني حذف حسابي؟', a: 'نعم، من صفحة الدعم الفني اضغط أيقونة الحذف في أعلى الشاشة. الحذف نهائي ولا يمكن التراجع عنه.'),
        _FaqItem(q: 'نسيت كلمة المرور، ماذا أفعل؟', a: 'في صفحة تسجيل الدخول في الموقع الرسمي  اضغط "نسيت كلمة المرور" وسيصلك رمز التحقق على بريدك الإلكتروني.'),       ],
    ),
    _FaqCategory(
      title: 'المدفوعات والاشتراكات',
      icon: Icons.payment_outlined,
      color: Color(0xFF43A047),
      items: [
        _FaqItem(q: 'ما طرق الدفع المتاحة؟', a: 'نقبل بطاقات Visa وMastercard وApple Pay وGoogle Pay والمحافظ الإلكترونية المحلية.'),
        _FaqItem(q: 'كيف أسترجع مبلغاً؟', a: 'يمكن طلب الاسترجاع خلال 7 أيام من الشراء عبر تذكرة دعم، وسيُعاد المبلغ خلال 5-10 أيام عمل.'),
        _FaqItem(q: 'كيف أعرف تاريخ تجديد اشتراكي؟', a: 'اذهب إلى الإعدادات ← الاشتراك لعرض تاريخ التجديد القادم وتفاصيل خطتك.'),
      ],
    ),
    _FaqCategory(
      title: 'المشاكل التقنية',
      icon: Icons.build_outlined,
      color: Color(0xFF1E88E5),
      items: [
        _FaqItem(q: 'التطبيق لا يعمل بشكل صحيح، ماذا أفعل؟', a: 'جرّب تسجيل الخروج وإعادة الدخول، أو أعد تشغيل التطبيق. إذا استمرت المشكلة أرسل تذكرة دعم.'),
        _FaqItem(q: 'لا أتلقى الإشعارات، كيف أحل المشكلة؟', a: 'تأكد من تفعيل الإشعارات في إعدادات هاتفك للتطبيق، وتأكد أن وضع "عدم الإزعاج" غير مفعّل.'),
        _FaqItem(q: 'الصور لا تحمّل، ما الحل؟', a: 'تحقق من اتصالك بالإنترنت. إذا كان الاتصال جيداً امسح الكاش من إعدادات التطبيق وحاول مرة أخرى.'),
      ],
    ),
    _FaqCategory(
      title: 'الطلبات والخدمات',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFF57C00),
      items: [
        _FaqItem(q: 'كيف أتابع حالة طلبي؟', a: 'من الصفحة الرئيسية للموقع اضغط "طلباتي" لمشاهدة الحالة الحالية لجميع طلباتك.'),
        _FaqItem(q: 'هل يمكن إلغاء طلب بعد تأكيده؟', a: 'يمكن إلغاء الطلب خلال 15 دقيقة من التأكيد فقط. بعدها يجب التواصل مع الدعم الفني.'),
        _FaqItem(q: 'لم يصلني رمز التحقق، ماذا أفعل؟', a: 'انتظر دقيقة ثم اطلب إعادة الإرسال. تأكد من صحة رقم هاتفك وأن الرسائل غير محظورة.'),
      ],
    ),
  ];

  List<_FaqCategory> get _filtered {
    if (_query.isEmpty) return _categories;
    return _categories.map((cat) {
      final items = cat.items.where((i) => i.q.contains(_query) || i.a.contains(_query)).toList();
      return items.isEmpty ? null : _FaqCategory(title: cat.title, icon: cat.icon, color: cat.color, items: items);
    }).whereType<_FaqCategory>().toList();
  }

  static double _fs(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);
  static double _sz(BuildContext ctx, double base) =>
      base * (MediaQuery.of(ctx).size.width / 390).clamp(0.85, 1.15);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('مركز المساعدة',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: _fs(context, 18))),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildSearch(context),
              ),
            ),
            if (_query.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildQuickLinks(context),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  _query.isEmpty ? 'الأسئلة الشائعة' : 'نتائج البحث (${filtered.fold(0, (s, c) => s + c.items.length)})',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(context, 17), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    const Icon(Icons.search_off_rounded, color: AppTheme.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text('لا توجد نتائج لـ "$_query"',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: _fs(context, 14))),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildCategory(context, filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildContactBanner(context),
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
    final heroH = (mq.size.height * 0.22).clamp(160.0, 210.0);
    final iconSz = (mq.size.width * 0.17).clamp(54.0, 78.0);
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: iconSz, height: iconSz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Icon(Icons.help_outline_rounded, color: Colors.white, size: iconSz * 0.46),
            ),
            Text('كيف يمكننا مساعدتك؟',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(ctx, 19), fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text('ابحث في قاعدة المعرفة أو تصفح الأسئلة',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: _fs(ctx, 12))),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext ctx) {
    return TextField(
      controller: _searchCtrl,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(ctx, 14)),
      onChanged: (v) => setState(() => _query = v.trim()),
      decoration: InputDecoration(
        hintText: 'ابحث عن سؤال...',
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary, size: _sz(ctx, 20)),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
            icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: _sz(ctx, 18)),
            onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
            : null,
        filled: true, fillColor: AppTheme.bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderColor, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        contentPadding: EdgeInsets.symmetric(vertical: _sz(ctx, 14)),
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext ctx) {
    final links = [
      _QuickLink(icon: Icons.rocket_launch_outlined, label: 'البداية', color: AppTheme.primary),
      _QuickLink(icon: Icons.receipt_long_outlined, label: 'الفواتير', color: Colors.green),
      _QuickLink(icon: Icons.lock_outline_rounded, label: 'الأمان', color: Colors.orange),
      _QuickLink(icon: Icons.info_outline_rounded, label: 'عن التطبيق', color: Colors.blue),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Text('روابط سريعة',
      //     style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(ctx, 17), fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      // Row(
      //   children: links.asMap().entries.map((e) {
      //     final l = e.value;
      //     final isLast = e.key == links.length - 1;
      //     return Expanded(
      //       child: Container(
      //         margin: EdgeInsets.only(left: isLast ? 8 : 8),
      //         padding: EdgeInsets.symmetric(vertical: _sz(ctx, 14)),
      //         decoration: BoxDecoration(
      //           color: AppTheme.bgCard,
      //           borderRadius: BorderRadius.circular(12),
      //           border: Border.all(color: l.color.withOpacity(0.25), width: 1),
      //         ),
      //         child: Column(mainAxisSize: MainAxisSize.min, children: [
      //           Icon(l.icon, color: l.color, size: _sz(ctx, 22)),
      //           const SizedBox(height: 6),
      //           Text(l.label,
      //               style: TextStyle(color: l.color, fontSize: _fs(ctx, 10), fontWeight: FontWeight.w600),
      //               textAlign: TextAlign.center),
      //         ]),
      //       ),
      //     );
      //   }).toList(),
      // ),
    ]);
  }

  Widget _buildCategory(BuildContext ctx, _FaqCategory cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cat.color.withOpacity(0.2), width: 1),
      ),
      child: Theme(
        data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _query.isNotEmpty,
          iconColor: cat.color,
          collapsedIconColor: AppTheme.textSecondary,
          leading: Container(
            width: _sz(ctx, 38), height: _sz(ctx, 38),
            decoration: BoxDecoration(color: cat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(cat.icon, color: cat.color, size: _sz(ctx, 20)),
          ),
          title: Text(cat.title,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(ctx, 14), fontWeight: FontWeight.w700)),
          subtitle: Text('${cat.items.length} سؤال',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: _fs(ctx, 11))),
          children: cat.items.map((i) => _buildFaqItem(ctx, i, cat.color)).toList(),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext ctx, _FaqItem item, Color color) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.7)),
        ),
        title: Text(item.q,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(ctx, 13), fontWeight: FontWeight.w600)),
        iconColor: color,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: Text(item.a,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: _fs(ctx, 13), height: 1.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBanner(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.all(_sz(ctx, 18)),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(children: [
        Container(
          width: _sz(ctx, 46), height: _sz(ctx, 46),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.headset_mic_outlined, color: AppTheme.primaryLight, size: _sz(ctx, 22)),
        ),
        SizedBox(width: _sz(ctx, 12)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('لم تجد إجابة؟',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: _fs(ctx, 14), fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('تواصل مع فريق الدعم الفني مباشرة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: _fs(ctx, 12))),
        ])),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(horizontal: _sz(ctx, 14), vertical: _sz(ctx, 10)),
          ),
          child: Text('تواصل',
              style: TextStyle(color: Colors.white, fontSize: _fs(ctx, 13), fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _FaqCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_FaqItem> items;
  const _FaqCategory({required this.title, required this.icon, required this.color, required this.items});
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _QuickLink {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickLink({required this.icon, required this.label, required this.color});
}