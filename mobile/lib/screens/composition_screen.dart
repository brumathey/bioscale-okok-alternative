import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';
import '../database/database_helper.dart';
import '../calculations/body_composition.dart';
import '../widgets/weight_hero_card.dart';
import '../widgets/metric_row.dart';
import '../widgets/body_composition_report.dart';

class CompositionScreen extends StatefulWidget {
  final int? measurementId;

  const CompositionScreen({super.key, this.measurementId});

  @override
  State<CompositionScreen> createState() => _CompositionScreenState();
}

class _CompositionScreenState extends State<CompositionScreen>
    with SingleTickerProviderStateMixin {
  final _screenshotController = ScreenshotController();
  late TabController _tabController;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _measurement;
  Map<String, dynamic>? _prevMeasurement;
  Map<String, dynamic> _metrics = {};
  Map<String, ClassificationResult> _classifications = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final user = await db.getActiveUser();
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    Map<String, dynamic>? m;
    if (widget.measurementId != null) {
      m = await db.getMeasurement(widget.measurementId!);
    } else {
      final measurements = await db.getMeasurements(user['id'] as int, limit: 1);
      m = measurements.isNotEmpty ? measurements.first : null;
    }

    Map<String, dynamic>? prev;
    if (m != null) {
      final allM = await db.getMeasurements(user['id'] as int, limit: 100);
      final idx = allM.indexWhere((x) => x['id'] == m!['id']);
      if (idx >= 0 && idx + 1 < allM.length) {
        prev = allM[idx + 1];
      }
    }

    Map<String, dynamic> metrics = {};
    Map<String, ClassificationResult> cls = {};
    if (m != null) {
      metrics = getAllMetrics(
        (m['weight_kg'] as num).toDouble(),
        (user['height_cm'] as num).toDouble(),
        (user['age'] as num).toInt(),
        user['sex'] as String,
        impedance: (m['impedance'] as num?)?.toDouble(),
        activityLevel: user['activity_level'] as String? ?? 'sedentary',
        waistCm: (user['waist_cm'] as num?)?.toDouble(),
        hipCm: (user['hip_cm'] as num?)?.toDouble(),
      );
      cls = getClassifications(
        metrics,
        user['sex'] as String,
        (user['age'] as num).toInt(),
        (user['height_cm'] as num).toDouble(),
      );
    }

    setState(() {
      _user = user;
      _measurement = m;
      _prevMeasurement = prev;
      _metrics = metrics;
      _classifications = cls;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_measurement == null) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        I18nService.t('composition.no_measurement'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          I18nService.t('common.weigh_now'),
                          style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildHeader(),
            ),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMetricsTab(),
                  _buildReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerHeight: 0,
        tabs: [
          Tab(
            height: 36,
            text: I18nService.t('report.tab_metrics'),
          ),
          Tab(
            height: 36,
            text: I18nService.t('report.tab_analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    final weight = (_measurement!['weight_kg'] as num).toDouble();
    final prevWeight = _prevMeasurement != null
        ? (_prevMeasurement!['weight_kg'] as num).toDouble()
        : null;
    final bmi = (_measurement!['bmi'] as num?)?.toDouble();

    final groups = {
      I18nService.t('composition.group_summary'): [
        'body_score', 'bmi', 'obesity_percent', 'ideal_weight', 'metabolic_age'
      ],
      I18nService.t('composition.group_fat'): [
        'body_fat', 'fat_mass', 'visceral_fat', 'subcutaneous_fat'
      ],
      I18nService.t('composition.group_muscle'): [
        'muscle_mass', 'muscle_mass_kg', 'smm_percent', 'smm', 'ffmi', 'smi', 'lbm'
      ],
      I18nService.t('composition.group_other'): [
        'body_water', 'water_mass', 'bone_mass', 'protein', 'bmr', 'whr', 'whtr'
      ],
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              color: AppColors.bgMain,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: WeightHeroCard(
                      weightKg: weight,
                      deltaWeight: prevWeight != null ? weight - prevWeight : null,
                      bmi: bmi,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < groups.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: AppColors.borderLight),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Text(
                              groups.keys.elementAt(i).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ...groups.values.elementAt(i).map((key) {
                            final cls = _classifications[key];
                            if (cls != null) {
                              return MetricRow(classification: cls);
                            }
                            return MetricRow(
                              classification: ClassificationResult(
                                value: 0,
                                unit: '',
                                name: I18nService.t('metric.$key'),
                                label: I18nService.t('metric.pending'),
                                color: 'info',
                                bounds: [],
                                desc: I18nService.t('metric.pending_desc'),
                                category: '',
                              ),
                              isMissing: true,
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      I18nService.t('composition.footnote'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/history'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  I18nService.t('composition.view_history'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    return BodyCompositionReport(
      metrics: _metrics,
      classifications: _classifications,
      sex: _user!['sex'] as String,
    );
  }

  Future<void> _shareAsImage() async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );
      if (imageBytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bioscale_composition.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'BioScale - ${I18nService.t('composition.title')}',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          color: AppColors.textPrimary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                I18nService.t('composition.title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_measurement != null)
                Text(
                  _formatDate(_measurement!['measured_at']),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        if (_measurement != null)
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: _shareAsImage,
            color: AppColors.blue,
          ),
      ],
    );
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '--';
    DateTime date;
    if (dt is String) {
      date = DateTime.tryParse(dt) ?? DateTime.now();
    } else {
      date = dt as DateTime;
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
