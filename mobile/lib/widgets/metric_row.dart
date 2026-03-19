import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../calculations/body_composition.dart';

class MetricRow extends StatefulWidget {
  final ClassificationResult classification;
  final bool isMissing;

  const MetricRow({
    super.key,
    required this.classification,
    this.isMissing = false,
  });

  @override
  State<MetricRow> createState() => _MetricRowState();
}

class _MetricRowState extends State<MetricRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.classification;
    final statusColor = AppColors.statusColor(c.color);
    final statusBg = AppColors.statusBgColor(c.color);

    return Column(
      children: [
        // Main row
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Metric name
                Expanded(
                  flex: 3,
                  child: Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isMissing
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isMissing
                        ? AppColors.bgMain
                        : statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.isMissing
                          ? AppColors.textMuted
                          : statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Value
                SizedBox(
                  width: 70,
                  child: Text(
                    widget.isMissing
                        ? '--'
                        : _formatValue(c.value, c.unit),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.isMissing
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        // Expanded detail
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (c.bounds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildZoneBar(c),
                ],
              ],
            ),
          ),
        Divider(height: 1, color: AppColors.borderLight.withValues(alpha: 0.5)),
      ],
    );
  }

  String _formatValue(double value, String unit) {
    if (unit == '' || unit == '/100') {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }
    if (unit == 'kcal' || unit == 'anos' || unit == 'years' || unit == 'ans' || unit == 'años') {
      return '${value.toInt()} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  Widget _buildZoneBar(ClassificationResult c) {
    if (c.bounds.length < 3) return const SizedBox.shrink();

    final boundsRange = c.bounds.last - c.bounds.first;
    if (boundsRange <= 0) return const SizedBox.shrink();

    final min = c.bounds.first - boundsRange * 0.3;
    final max = c.bounds.last + boundsRange * 0.3;
    final range = max - min;

    final pos = ((c.value - min) / range).clamp(0.0, 1.0);

    // Calculate zone edges: [min, b0, b1, b2, max]
    final edges = [min, ...c.bounds, max];
    // Each zone width as flex value (multiplied by 1000 for int precision)
    final flexValues = <int>[];
    for (int i = 0; i < edges.length - 1; i++) {
      flexValues.add(((edges[i + 1] - edges[i]) / range * 1000).round().clamp(1, 1000));
    }

    const barHeight = 6.0;
    const radius = Radius.circular(3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: List.generate(c.zoneColors.length, (i) {
                final isFirst = i == 0;
                final isLast = i == c.zoneColors.length - 1;
                return Expanded(
                  flex: flexValues[i],
                  child: Container(
                    height: barHeight,
                    margin: EdgeInsets.only(
                      left: isFirst ? 0 : 0.5,
                      right: isLast ? 0 : 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusColor(c.zoneColors[i]).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.only(
                        topLeft: isFirst ? radius : Radius.zero,
                        bottomLeft: isFirst ? radius : Radius.zero,
                        topRight: isLast ? radius : Radius.zero,
                        bottomRight: isLast ? radius : Radius.zero,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned(
              left: (pos * width).clamp(4, width - 4) - 4,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
