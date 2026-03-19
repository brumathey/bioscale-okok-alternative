import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';

class CompositionBar extends StatelessWidget {
  final String name;
  final double value;
  final double totalWeight;
  final String statusLabel;
  final String statusColor;
  final Color barColor;
  final double? rangeStart;
  final double? rangeEnd;

  const CompositionBar({
    super.key,
    required this.name,
    required this.value,
    required this.totalWeight,
    required this.statusLabel,
    required this.statusColor,
    required this.barColor,
    this.rangeStart,
    this.rangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final fillRatio = totalWeight > 0 ? (value / totalWeight).clamp(0.0, 1.0) : 0.0;
    final tagColor = AppColors.statusColor(statusColor);
    final tagBgColor = AppColors.statusBgColor(statusColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: colored bullet + name ... status tag
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tagBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tagColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Row 2 + 3: bar with value text inside
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final filledWidth = barWidth * fillRatio;

            // Standard range positions
            final hasRange = rangeStart != null && rangeEnd != null && totalWeight > 0;
            final rangeStartFraction = hasRange ? (rangeStart! / totalWeight).clamp(0.0, 1.0) : 0.0;
            final rangeEndFraction = hasRange ? (rangeEnd! / totalWeight).clamp(0.0, 1.0) : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The bar
                Container(
                  height: 24,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: AppColors.bgMain,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // Filled portion
                      Container(
                        height: 24,
                        width: filledWidth,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Value text inside bar
                      if (filledWidth > 30)
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              '${value.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _textColorForBar(barColor),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          left: filledWidth + 6,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              '${value.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Standard range marker below bar
                if (hasRange) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 16,
                    width: barWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Range bracket line
                        Positioned(
                          left: barWidth * rangeStartFraction,
                          width: barWidth * (rangeEndFraction - rangeStartFraction),
                          top: 0,
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColors.textMuted,
                                      width: 1.5,
                                    ),
                                    right: BorderSide(
                                      color: AppColors.textMuted,
                                      width: 1.5,
                                    ),
                                    bottom: BorderSide(
                                      color: AppColors.textMuted,
                                      width: 1.5,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(2),
                                    bottomRight: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // "Faixa padrão" label centered on the range
                        Positioned(
                          left: barWidth * rangeStartFraction,
                          width: barWidth * (rangeEndFraction - rangeStartFraction),
                          top: 5,
                          child: Text(
                            I18nService.t('standard_range'),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// Returns white for dark bar colors, dark for light bar colors.
  Color _textColorForBar(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.45 ? AppColors.textPrimary : Colors.white;
  }
}
