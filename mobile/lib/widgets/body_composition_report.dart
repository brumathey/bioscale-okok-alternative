import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';
import '../calculations/body_composition.dart';
import 'body_silhouette.dart';
import 'composition_bar.dart';
import 'body_type_grid.dart';
import 'weight_control_tips.dart';

class BodyCompositionReport extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final Map<String, ClassificationResult> classifications;
  final String sex;

  const BodyCompositionReport({
    super.key,
    required this.metrics,
    required this.classifications,
    required this.sex,
  });

  @override
  Widget build(BuildContext context) {
    final weight = (metrics['weight_kg'] as num).toDouble();
    final waterMass = (metrics['water_mass_kg'] as num).toDouble();
    final fatMass = (metrics['fat_mass_kg'] as num).toDouble();
    final proteinMass = (metrics['protein_percent'] as num).toDouble() *
        weight /
        100.0;
    final boneMass = (metrics['bone_mass_kg'] as num).toDouble();
    final waterPercent = (metrics['body_water_percent'] as num).toDouble();
    final bmi = (metrics['bmi'] as num).toDouble();
    final fatPercent = (metrics['body_fat_percent'] as num).toDouble();

    final bodyType = getBodyType(bmi, fatPercent, sex);
    final controlData = getWeightControlData(metrics, sex);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildCompositionSection(
            weight, waterMass, fatMass, proteinMass, boneMass, waterPercent,
          ),
          const SizedBox(height: 16),
          _buildBodyTypeSection(bodyType),
          const SizedBox(height: 16),
          _buildWeightTipsSection(controlData),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCompositionSection(
    double weight,
    double waterMass,
    double fatMass,
    double proteinMass,
    double boneMass,
    double waterPercent,
  ) {
    final waterCls = classifications['body_water'];
    final fatCls = classifications['body_fat'];
    final proteinCls = classifications['protein'];
    final boneCls = classifications['bone_mass'];

    return _buildCard([
      _buildSectionTitle(I18nService.t('report.composition_title')),
      const SizedBox(height: 4),
      Text(
        I18nService.t('report.composition_subtitle'),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            height: 240,
            child: BodySilhouette(waterPercent: waterPercent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 20),
                Text(
                  weight.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildMiniCompositionRow(
                  I18nService.t('report.water'),
                  waterMass,
                  waterCls?.label ?? '',
                  waterCls?.color ?? 'info',
                  const Color(0xFFB3D4F0),
                ),
                const SizedBox(height: 12),
                _buildMiniCompositionRow(
                  I18nService.t('report.fat'),
                  fatMass,
                  fatCls?.label ?? '',
                  fatCls?.color ?? 'info',
                  const Color(0xFF7BB3E0),
                ),
                const SizedBox(height: 12),
                _buildMiniCompositionRow(
                  I18nService.t('report.protein'),
                  double.parse(proteinMass.toStringAsFixed(1)),
                  proteinCls?.label ?? '',
                  proteinCls?.color ?? 'info',
                  const Color(0xFF4A90D9),
                ),
                const SizedBox(height: 12),
                _buildMiniCompositionRow(
                  I18nService.t('report.bones'),
                  boneMass,
                  boneCls?.label ?? '',
                  boneCls?.color ?? 'info',
                  const Color(0xFF2C6BAD),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildCompositionBars(weight, waterMass, fatMass, proteinMass, boneMass),
    ]);
  }

  Widget _buildMiniCompositionRow(
    String name,
    double value,
    String statusLabel,
    String statusColor,
    Color bulletColor,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: bulletColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.statusColor(statusColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCompositionBars(
    double weight,
    double waterMass,
    double fatMass,
    double proteinMass,
    double boneMass,
  ) {
    final waterCls = classifications['body_water'];
    final fatCls = classifications['body_fat'];
    final proteinCls = classifications['protein'];
    final boneCls = classifications['bone_mass'];

    return Column(
      children: [
        CompositionBar(
          name: I18nService.t('report.water'),
          value: waterMass,
          totalWeight: weight,
          statusLabel: waterCls?.label ?? '',
          statusColor: waterCls?.color ?? 'info',
          barColor: const Color(0xFFB3D4F0),
          rangeStart: waterCls != null && waterCls.bounds.length >= 2
              ? waterCls.bounds[0] * weight / 100
              : null,
          rangeEnd: waterCls != null && waterCls.bounds.length >= 2
              ? waterCls.bounds[1] * weight / 100
              : null,
        ),
        const SizedBox(height: 10),
        CompositionBar(
          name: I18nService.t('report.fat'),
          value: fatMass,
          totalWeight: weight,
          statusLabel: fatCls?.label ?? '',
          statusColor: fatCls?.color ?? 'info',
          barColor: const Color(0xFF7BB3E0),
          rangeStart: fatCls != null && fatCls.bounds.length >= 2
              ? fatCls.bounds[0] * weight / 100
              : null,
          rangeEnd: fatCls != null && fatCls.bounds.length >= 2
              ? fatCls.bounds[1] * weight / 100
              : null,
        ),
        const SizedBox(height: 10),
        CompositionBar(
          name: I18nService.t('report.protein'),
          value: proteinMass,
          totalWeight: weight,
          statusLabel: proteinCls?.label ?? '',
          statusColor: proteinCls?.color ?? 'info',
          barColor: const Color(0xFF4A90D9),
          rangeStart: proteinCls != null && proteinCls.bounds.length >= 2
              ? proteinCls.bounds[0] * weight / 100
              : null,
          rangeEnd: proteinCls != null && proteinCls.bounds.length >= 2
              ? proteinCls.bounds[1] * weight / 100
              : null,
        ),
        const SizedBox(height: 10),
        CompositionBar(
          name: I18nService.t('report.bones'),
          value: boneMass,
          totalWeight: weight,
          statusLabel: boneCls?.label ?? '',
          statusColor: boneCls?.color ?? 'info',
          barColor: const Color(0xFF2C6BAD),
          rangeStart: boneCls != null && boneCls.bounds.length >= 2
              ? boneCls.bounds[0]
              : null,
          rangeEnd: boneCls != null && boneCls.bounds.length >= 2
              ? boneCls.bounds[1]
              : null,
        ),
      ],
    );
  }

  Widget _buildBodyTypeSection(Map<String, dynamic> bodyType) {
    return _buildCard([
      _buildSectionTitle(I18nService.t('report.body_type_title')),
      const SizedBox(height: 16),
      BodyTypeGrid(
        activeRow: bodyType['row'] as int,
        activeCol: bodyType['col'] as int,
        bodyTypeKey: bodyType['key'] as String,
        fatLow: (bodyType['fat_low'] as num).toDouble(),
        fatHigh: (bodyType['fat_high'] as num).toDouble(),
      ),
    ]);
  }

  Widget _buildWeightTipsSection(Map<String, dynamic> data) {
    return _buildCard([
      _buildSectionTitle(I18nService.t('report.weight_tips_title')),
      const SizedBox(height: 16),
      WeightControlTips(
        weightDelta: (data['weight_delta'] as num).toDouble(),
        muscleDelta: (data['muscle_delta'] as num).toDouble(),
        fatDelta: (data['fat_delta'] as num).toDouble(),
        idealWeight: (data['ideal_weight'] as num).toDouble(),
        currentWeight: (data['current_weight'] as num).toDouble(),
        currentMuscle: (data['current_muscle'] as num).toDouble(),
        idealMuscle: (data['ideal_muscle_mass'] as num).toDouble(),
        currentFat: (data['current_fat'] as num).toDouble(),
        idealFat: (data['ideal_fat_mass'] as num).toDouble(),
      ),
    ]);
  }
}
