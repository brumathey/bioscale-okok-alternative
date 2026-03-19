import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';

const bodyTypeKeys = [
  ['athlete_body', 'muscular_obesity', 'obesity'],
  ['muscular', 'healthy', 'slightly_overweight'],
  ['lean_muscular', 'lean', 'hidden_obesity'],
  ['skeletal_lean', 'slightly_underweight', 'empty'],
];

class BodyTypeGrid extends StatelessWidget {
  final int activeRow; // 0-3, current user's row
  final int activeCol; // 0-2, current user's column
  final String bodyTypeKey; // e.g., 'slightly_overweight'
  final double fatLow; // Low fat threshold (12% for M, 22% for F)
  final double fatHigh; // High fat threshold (18% for M, 30% for F)

  const BodyTypeGrid({
    super.key,
    required this.activeRow,
    required this.activeCol,
    required this.bodyTypeKey,
    required this.fatLow,
    required this.fatHigh,
  });

  bool _isActive(int row, int col) {
    return row == activeRow && col == activeCol;
  }

  bool _isEmpty(int row, int col) {
    return row == 3 && col == 2;
  }

  Widget _buildCell(int row, int col) {
    final empty = _isEmpty(row, col);
    final active = _isActive(row, col) && !empty;
    final key = bodyTypeKeys[row][col];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.redLight : Colors.white,
        border: Border.all(
          color: active ? AppColors.red : AppColors.borderLight,
          width: active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          empty ? '' : I18nService.t('body_type.$key'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: active ? 12 : 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.red : AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBmiLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid with BMI axis
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BMI Y-axis labels
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  // Row 0 height placeholder
                  const SizedBox(height: 48),
                  // "24,9" between row 0 and row 1
                  _buildBmiLabel('24,9'),
                  // Row 1 height placeholder
                  const SizedBox(height: 40),
                  // Row 2 height placeholder (rows 1-2 share the 18.5-24.9 range)
                  const SizedBox(height: 40),
                  // "18,5" between row 2 and row 3
                  _buildBmiLabel('18,5'),
                ],
              ),
            ),
            // Grid columns
            Expanded(
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: List.generate(4, (row) {
                  return TableRow(
                    children: List.generate(3, (col) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: col > 0 ? 4 : 0,
                          top: row > 0 ? 4 : 0,
                        ),
                        child: _buildCell(row, col),
                      );
                    }),
                  );
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Bottom axis labels
        Row(
          children: [
            // "BMI" label at bottom-left
            const SizedBox(
              width: 28,
              child: Text(
                'BMI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            // Fat axis labels spread across the grid width
            Expanded(
              child: Column(
                children: [
                  // Fat % threshold markers
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${fatLow.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Gordura',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${fatHigh.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Body type title
        Text(
          I18nService.t('body_type.$bodyTypeKey'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        // Body type description
        Text(
          I18nService.t('body_type_desc.$bodyTypeKey'),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
