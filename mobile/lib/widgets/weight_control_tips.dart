import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';

class WeightControlTips extends StatelessWidget {
  final double weightDelta;
  final double muscleDelta;
  final double fatDelta;
  final double idealWeight;
  final double currentWeight;
  final double currentMuscle;
  final double idealMuscle;
  final double currentFat;
  final double idealFat;

  const WeightControlTips({
    super.key,
    required this.weightDelta,
    required this.muscleDelta,
    required this.fatDelta,
    required this.idealWeight,
    required this.currentWeight,
    required this.currentMuscle,
    required this.idealMuscle,
    required this.currentFat,
    required this.idealFat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicatorRow(
            icon: Icons.monitor_weight_outlined,
            label: '${I18nService.t('report.weight_label')} Kg',
            delta: weightDelta,
            idealValue: idealWeight,
            currentValue: currentWeight,
            invertColor: false,
            showIdealLabel: true,
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow(
            icon: Icons.fitness_center_outlined,
            label: I18nService.t('report.muscle_label'),
            delta: muscleDelta,
            idealValue: idealMuscle,
            currentValue: currentMuscle,
            invertColor: true,
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow(
            icon: Icons.water_drop_outlined,
            label: '${I18nService.t('report.fat_label')} Kg',
            delta: fatDelta,
            idealValue: idealFat,
            currentValue: currentFat,
            invertColor: false,
          ),
          const SizedBox(height: 16),
          Text(
            _getWeightTipText(),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow({
    required IconData icon,
    required String label,
    required double delta,
    required double idealValue,
    required double currentValue,
    required bool invertColor,
    bool showIdealLabel = false,
  }) {
    final Color deltaColor = _getDeltaColor(delta, invertColor);
    final String deltaText = _formatDelta(delta);
    final double markerPosition = _calcMarkerPosition(idealValue, delta);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              deltaText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: deltaColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProgressBar(markerPosition),
        if (showIdealLabel) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${I18nService.t('report.ideal_weight')} ${idealWeight.toStringAsFixed(1)}Kg',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(double markerPosition) {
    const double barHeight = 6;
    const double markerHeight = 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;
        final double markerX = (markerPosition * barWidth).clamp(2, barWidth - 2);

        return SizedBox(
          height: markerHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Two-tone bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Row(
                  children: [
                    Expanded(
                      flex: (markerPosition * 100).round().clamp(1, 99),
                      child: Container(
                        height: barHeight,
                        color: const Color(0xFF5B9BD5),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - markerPosition) * 100).round().clamp(1, 99),
                      child: Container(
                        height: barHeight,
                        color: const Color(0xFF7BB3E0),
                      ),
                    ),
                  ],
                ),
              ),
              // Marker
              Positioned(
                left: markerX - 1,
                top: 0,
                child: Container(
                  width: 2,
                  height: markerHeight,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDeltaColor(double delta, bool invertColor) {
    if (delta.abs() < 0.1) return AppColors.green;
    if (invertColor) {
      // Muscle: positive = good (green), negative = bad (red)
      return delta > 0 ? AppColors.green : AppColors.red;
    } else {
      // Weight/Fat: positive = bad (red), negative = needs attention (green)
      return delta > 0 ? AppColors.red : AppColors.green;
    }
  }

  String _formatDelta(double delta) {
    final String sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)}';
  }

  double _calcMarkerPosition(double idealValue, double delta) {
    final double total = idealValue + delta.abs();
    if (total <= 0) return 0.5;
    return (idealValue / total).clamp(0.05, 0.95);
  }

  String _getWeightTipText() {
    if (weightDelta.abs() < 0.5) {
      return I18nService.t('report.weight_tip_ideal');
    } else if (weightDelta > 0) {
      return I18nService.t('report.weight_tip_lose');
    } else {
      return I18nService.t('report.weight_tip_gain');
    }
  }
}
