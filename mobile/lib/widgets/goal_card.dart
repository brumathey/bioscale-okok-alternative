import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';
import '../database/database_helper.dart';
import 'goal_gauge.dart';

class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final double? currentWeight;
  final double? idealWeight;
  final List<Map<String, dynamic>> measurements;
  final VoidCallback? onGoalUpdated;

  const GoalCard({
    super.key,
    required this.goal,
    this.currentWeight,
    this.idealWeight,
    this.measurements = const [],
    this.onGoalUpdated,
  });

  void _showEditGoal(BuildContext context) {
    final targetWeight = (goal['target_value'] as num).toDouble();
    final controller = TextEditingController(text: targetWeight.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                I18nService.t('overview.goal_define'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${I18nService.t('overview.goal_target')} (kg)',
                  suffixText: 'kg',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              if (idealWeight != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      controller.text = idealWeight!.toStringAsFixed(1);
                    },
                    child: Text(
                      I18nService.t('overview.goal_use_ideal')
                          .replaceAll('{weight}', idealWeight!.toStringAsFixed(1)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final val = double.tryParse(controller.text.replaceAll(',', '.'));
                    if (val == null || val < 20 || val > 250) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(I18nService.t('overview.goal_invalid'))),
                      );
                      return;
                    }
                    final db = DatabaseHelper.instance;
                    await db.updateGoal(goal['id'] as int, {'target_value': val});
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    onGoalUpdated?.call();
                  },
                  child: Text(I18nService.t('overview.goal_save')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetWeight = (goal['target_value'] as num).toDouble();

    if (currentWeight == null) {
      return _buildCard(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Text(
              '${I18nService.t('overview.goal_target')}: ${targetWeight.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              I18nService.t('overview.no_measurements'),
              style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Get start weight from oldest measurement in history
    final startWeight = measurements.isNotEmpty
        ? (measurements.last['weight_kg'] as num).toDouble()
        : currentWeight!;

    return _buildCard(
      context: context,
      child: Column(
        children: [
          _buildHeader(context),
          GoalGauge(
            startWeight: startWeight,
            currentWeight: currentWeight!,
            targetWeight: targetWeight,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            I18nService.t('overview.goal_title'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showEditGoal(context),
          child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
