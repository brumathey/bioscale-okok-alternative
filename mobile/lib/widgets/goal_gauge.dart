import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';

class GoalGauge extends StatelessWidget {
  final double startWeight;
  final double currentWeight;
  final double targetWeight;

  const GoalGauge({
    super.key,
    required this.startWeight,
    required this.currentWeight,
    required this.targetWeight,
  });

  double get _progressPercent {
    final totalRange = (startWeight - targetWeight).abs();
    if (totalRange < 0.1) return 1.0;
    final currentProgress = (startWeight - currentWeight).abs();
    // If user went past start in wrong direction, clamp to 0
    final isLoss = targetWeight < startWeight;
    if (isLoss && currentWeight > startWeight) return 0.0;
    if (!isLoss && currentWeight < startWeight) return 0.0;
    return (currentProgress / totalRange).clamp(0.0, 1.0);
  }

  bool get _isReached => (currentWeight - targetWeight).abs() < 0.5;

  Color get _progressColor {
    final p = _progressPercent;
    if (p >= 0.75) return AppColors.greenDark;
    if (p >= 0.4) return AppColors.green;
    if (p >= 0.15) return AppColors.yellow;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progressPercent * 100).round();
    final diff = (currentWeight - targetWeight).abs();
    final isLoss = targetWeight < currentWeight;

    String statusText;
    Color statusColor;
    if (_isReached) {
      statusText = I18nService.t('overview.goal_reached');
      statusColor = AppColors.greenDark;
    } else if (isLoss) {
      statusText = I18nService.t('overview.goal_remain')
          .replaceAll('{diff}', diff.toStringAsFixed(1));
      statusColor = AppColors.blue;
    } else {
      statusText = I18nService.t('overview.goal_gain')
          .replaceAll('{diff}', diff.toStringAsFixed(1));
      statusColor = AppColors.blue;
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        // Gauge
        SizedBox(
          width: 220,
          height: 130,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Gauge arc
              CustomPaint(
                size: const Size(220, 130),
                painter: _GaugePainter(
                  progress: _progressPercent,
                ),
              ),
              // Center weight text
              Positioned(
                bottom: 0,
                child: Column(
                  children: [
                    Text(
                      currentWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Start weight label (left)
              Positioned(
                left: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18nService.t('overview.goal_start'),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      startWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Target weight label (right)
              Positioned(
                right: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      I18nService.t('overview.goal_target'),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      targetWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Status row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _progressColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _progressColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 – 1.0

  _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;
    const startAngle = pi; // left (180°)
    const sweepAngle = pi; // full semicircle

    // ── Background arc ──────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // ── Progress arc with gradient ──────────────────────────────────────
    if (progress > 0.01) {
      final progressSweep = sweepAngle * progress;

      // Create gradient shader
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: const [
          AppColors.red,
          AppColors.yellow,
          AppColors.green,
          AppColors.greenDark,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      );

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);

      canvas.drawArc(
        rect,
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );
    }

    // ── Needle ──────────────────────────────────────────────────────────
    final needleAngle = startAngle + sweepAngle * progress;
    final needleLength = radius + 2;
    final needleTip = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    // Needle line
    final needlePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw from a point slightly away from center (not from dead center)
    final needleBase = Offset(
      center.dx + 18 * cos(needleAngle),
      center.dy + 18 * sin(needleAngle),
    );
    canvas.drawLine(needleBase, needleTip, needlePaint);

    // Needle pivot circle
    final pivotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, pivotPaint);

    final pivotBorder = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 8, pivotBorder);

    // Small dot at needle tip
    final tipPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needleTip, 4, tipPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
