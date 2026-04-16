import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';

enum OverallStatus { operational, degraded, outage }
enum ServiceState { operational, degraded, maintenance, outage }
enum IncidentStatus { investigating, maintenance, resolved }

class SystemStatusPage extends StatefulWidget {
  const SystemStatusPage({super.key});

  @override
  State<SystemStatusPage> createState() => _SystemStatusPageState();
}

class _SystemStatusPageState extends State<SystemStatusPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _isRefreshing = false;
  bool _isLoading = true;
  String? _error;

  OverallStatus _overall = OverallStatus.operational;
  String _lastChecked = 'الآن';

  List<_ServiceStatus> _services = [];
  List<_Incident> _incidents = [];

  static const String _baseUrl = 'https://playzoone.com/api';

  static double _fs(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    return base * (w / 390).clamp(0.85, 1.15);
  }

  static double _sz(BuildContext ctx, double base) {
    final w = MediaQuery.of(ctx).size.width;
    return base * (w / 390).clamp(0.85, 1.15);
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadSystemStatus();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSystemStatus() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '$_baseUrl/system-status',
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;

      final services = ((data['services'] ?? []) as List)
          .map((e) => _ServiceStatus.fromJson(e as Map<String, dynamic>))
          .toList();

      final incidents = ((data['incidents'] ?? []) as List)
          .map((e) => _Incident.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _overall = _overallFromString((data['overall_status'] ?? 'operational').toString());
        _lastChecked = (data['last_checked'] ?? 'الآن').toString();
        _services = services;
        _incidents = incidents;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data?['message']?.toString() ?? 'فشل تحميل حالة النظام';
        _isLoading = false;
      });
      debugPrint('System status error: ${e.message}');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقع';
        _isLoading = false;
      });
      debugPrint('System status unknown error: $e');
    }
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }
    await _loadSystemStatus();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  OverallStatus _overallFromString(String value) {
    switch (value) {
      case 'degraded':
        return OverallStatus.degraded;
      case 'outage':
        return OverallStatus.outage;
      default:
        return OverallStatus.operational;
    }
  }

  Color _overallColor() {
    switch (_overall) {
      case OverallStatus.operational:
        return const Color(0xFF43A047);
      case OverallStatus.degraded:
        return Colors.orange;
      case OverallStatus.outage:
        return AppTheme.primary;
    }
  }

  String _overallText() {
    switch (_overall) {
      case OverallStatus.operational:
        return 'جميع الأنظمة تعمل بشكل طبيعي';
      case OverallStatus.degraded:
        return 'بعض الخدمات تعاني من مشاكل';
      case OverallStatus.outage:
        return 'عطل في بعض الخدمات الرئيسية';
    }
  }

  IconData _overallIcon() {
    switch (_overall) {
      case OverallStatus.operational:
        return Icons.check_circle_rounded;
      case OverallStatus.degraded:
        return Icons.warning_amber_rounded;
      case OverallStatus.outage:
        return Icons.error_rounded;
    }
  }

  double get _avgLatency {
    final values = _services
        .map((s) => s.latencyNumber)
        .where((v) => v != null)
        .cast<int>()
        .toList();

    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double get _avgUptime {
    final values = _services
        .map((s) => s.uptimeNumber)
        .where((v) => v != null)
        .cast<double>()
        .toList();

    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get _healthyServicesCount =>
      _services.where((s) => s.state == ServiceState.operational).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'حالة النظام',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: _fs(context, 18),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppTheme.textSecondary,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary),
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        )
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.textSecondary, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: _fs(context, 14),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSystemStatus,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        )
            : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildOverallBanner(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildUptimeRow(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  'حالة الخدمات',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(context, 17),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildServiceCard(context, _services[i]),
                  childCount: _services.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: Text(
                  'سجل الأحداث',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(context, 17),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildIncidentCard(context, _incidents[i]),
                  childCount: _incidents.length,
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
    final iconSz = (mq.size.width * 0.16).clamp(50.0, 76.0);

    return Container(
      height: heroH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF001A0A), AppTheme.bgDark],
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
                  color: _overallColor().withOpacity(0.15),
                  border: Border.all(
                      color: _overallColor().withOpacity(0.4), width: 1.5),
                ),
                child: Icon(_overallIcon(),
                    color: _overallColor(), size: iconSz * 0.46),
              ),
              Text(
                'حالة النظام',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: _fs(ctx, 19),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'آخر تحديث: $_lastChecked',
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

  Widget _buildOverallBanner(BuildContext ctx) {
    final color = _overallColor();
    return Container(
      padding: EdgeInsets.all(_sz(ctx, 18)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(_overallIcon(), color: color, size: _sz(ctx, 28)),
          SizedBox(width: _sz(ctx, 12)),
          Expanded(
            child: Text(
              _overallText(),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: _fs(ctx, 15),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUptimeRow(BuildContext ctx) {
    final stats = [
      _StatItem(
        label: 'وقت التشغيل',
        value: '${_avgUptime.toStringAsFixed(1)}%',
        color: Colors.green,
      ),
      _StatItem(
        label: 'متوسط الاستجابة',
        value: '${_avgLatency.toStringAsFixed(0)}ms',
        color: Colors.blue,
      ),
      _StatItem(
        label: 'الخدمات الكاملة',
        value: '$_healthyServicesCount/${_services.length}',
        color: Colors.orange,
      ),
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: s == stats.last ? 0 : 8),
            padding: EdgeInsets.symmetric(vertical: _sz(ctx, 14), horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.color.withOpacity(0.25), width: 1),
            ),
            child: Column(
              children: [
                Text(
                  s.value,
                  style: TextStyle(
                    color: s.color,
                    fontSize: _fs(ctx, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: _fs(ctx, 10),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard(BuildContext ctx, _ServiceStatus svc) {
    Color stateColor;
    String stateLabel;
    IconData stateIcon;

    switch (svc.state) {
      case ServiceState.operational:
        stateColor = Colors.green;
        stateLabel = 'يعمل';
        stateIcon = Icons.check_circle_outline_rounded;
        break;
      case ServiceState.degraded:
        stateColor = Colors.orange;
        stateLabel = 'بطيء';
        stateIcon = Icons.warning_amber_outlined;
        break;
      case ServiceState.maintenance:
        stateColor = Colors.blue;
        stateLabel = 'صيانة';
        stateIcon = Icons.build_circle_outlined;
        break;
      case ServiceState.outage:
        stateColor = AppTheme.primary;
        stateLabel = 'متوقف';
        stateIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(_sz(ctx, 14)),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stateColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
        
          Container(
            width: _sz(ctx, 40),
            height: _sz(ctx, 40),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(svc.icon, color: stateColor, size: _sz(ctx, 20)),
          ),
          SizedBox(width: _sz(ctx, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  svc.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(ctx, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'تشغيل: ${svc.uptime}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(ctx, 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'استجابة: ${svc.latency}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: _fs(ctx, 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stateIcon, color: stateColor, size: _sz(ctx, 13)),
                const SizedBox(width: 4),
                Text(
                  stateLabel,
                  style: TextStyle(
                    color: stateColor,
                    fontSize: _fs(ctx, 11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(BuildContext ctx, _Incident incident) {
    String statusLabel;
    switch (incident.status) {
      case IncidentStatus.investigating:
        statusLabel = 'قيد التحقيق';
        break;
      case IncidentStatus.maintenance:
        statusLabel = 'صيانة';
        break;
      case IncidentStatus.resolved:
        statusLabel = 'تم الحل';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(_sz(ctx, 16)),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: incident.color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: _fs(ctx, 14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: incident.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: incident.color,
                    fontSize: _fs(ctx, 11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            incident.description,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: _fs(ctx, 13),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  color: AppTheme.textSecondary, size: _sz(ctx, 13)),
              const SizedBox(width: 4),
              Text(
                incident.time,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: _fs(ctx, 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceStatus {
  final String name;
  final IconData icon;
  final ServiceState state;
  final String uptime;
  final String latency;

  const _ServiceStatus({
    required this.name,
    required this.icon,
    required this.state,
    required this.uptime,
    required this.latency,
  });

  factory _ServiceStatus.fromJson(Map<String, dynamic> json) {
    final stateValue = (json['state'] ?? 'operational').toString();
    final typeValue = (json['type'] ?? '').toString();

    return _ServiceStatus(
      name: (json['name'] ?? '').toString(),
      icon: _iconFromType(typeValue),
      state: _stateFromString(stateValue),
      uptime: (json['uptime'] ?? '—').toString(),
      latency: (json['latency'] ?? '—').toString(),
    );
  }

  int? get latencyNumber {
    final raw = latency.replaceAll('ms', '').trim();
    return int.tryParse(raw);
  }

  double? get uptimeNumber {
    final raw = uptime.replaceAll('%', '').trim();
    return double.tryParse(raw);
  }

  static ServiceState _stateFromString(String value) {
    switch (value) {
      case 'degraded':
        return ServiceState.degraded;
      case 'maintenance':
        return ServiceState.maintenance;
      case 'outage':
        return ServiceState.outage;
      default:
        return ServiceState.operational;
    }
  }

  static IconData _iconFromType(String value) {
    switch (value) {
      case 'server':
        return Icons.dns_outlined;
      case 'database':
        return Icons.storage_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'notifications':
        return Icons.notifications_outlined;
      case 'stream':
        return Icons.live_tv_outlined;
      case 'files':
        return Icons.cloud_upload_outlined;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }
}

class _Incident {
  final String title;
  final String description;
  final String time;
  final IncidentStatus status;
  final Color color;

  const _Incident({
    required this.title,
    required this.description,
    required this.time,
    required this.status,
    required this.color,
  });

  factory _Incident.fromJson(Map<String, dynamic> json) {
    final statusValue = (json['status'] ?? 'investigating').toString();

    return _Incident(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      status: _statusFromString(statusValue),
      color: _colorFromStatus(statusValue),
    );
  }

  static IncidentStatus _statusFromString(String value) {
    switch (value) {
      case 'maintenance':
        return IncidentStatus.maintenance;
      case 'resolved':
        return IncidentStatus.resolved;
      default:
        return IncidentStatus.investigating;
    }
  }

  static Color _colorFromStatus(String value) {
    switch (value) {
      case 'maintenance':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
}