import 'package:flutter/material.dart';

/// A widget that draws a simplified human body silhouette filled with a
/// water-level indicator from bottom to top based on [waterPercent].
class BodySilhouette extends StatelessWidget {
  const BodySilhouette({
    super.key,
    required this.waterPercent,
  });

  /// Water percentage (0-100) controlling how high the fill reaches.
  final double waterPercent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BodySilhouettePainter(
        waterPercent: waterPercent.clamp(0, 100),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BodySilhouettePainter extends CustomPainter {
  _BodySilhouettePainter({required this.waterPercent});

  final double waterPercent;

  static const _outlineColor = Color(0xFFD0DEF0);
  static const _fillColor = Color(0xFF4A90D9);

  /// Builds a closed path representing a simplified human body silhouette.
  ///
  /// All coordinates are expressed as fractions of [w] (width) and [h]
  /// (height) so the figure scales to any canvas size.
  Path _buildBodyPath(double w, double h) {
    final path = Path();

    // ---- Proportional references ----
    final cx = w / 2; // centre-x

    // Head
    final headRadius = w * 0.12;
    final headCy = h * 0.08;

    // Neck
    final neckW = w * 0.06;
    final neckTop = headCy + headRadius;
    final neckBottom = h * 0.18;

    // Shoulders / torso
    final shoulderW = w * 0.28;
    final shoulderY = neckBottom;
    final torsoBottomY = h * 0.55;
    final hipW = w * 0.22;

    // Arms
    final armOuterW = w * 0.38;
    final elbowY = h * 0.40;
    final handY = h * 0.52;
    final armThick = w * 0.05;

    // Legs
    final legOuterW = w * 0.20;
    final legInnerW = w * 0.04;
    final kneeY = h * 0.72;
    final footY = h * 0.97;
    final legBottomW = w * 0.08;
    final crotchY = h * 0.58;

    // ---------- Draw path (clockwise from top of head) ----------

    // Head circle – approximate with arcTo
    path.addOval(Rect.fromCircle(center: Offset(cx, headCy), radius: headRadius));

    // Body below the head is a separate sub-path.
    final body = Path();

    // Start at left side of neck
    body.moveTo(cx - neckW, neckTop);

    // Left neck down to left shoulder
    body.lineTo(cx - neckW, shoulderY);
    body.lineTo(cx - shoulderW, shoulderY + h * 0.02);

    // Left arm – outer edge going down
    body.quadraticBezierTo(
      cx - armOuterW, shoulderY + h * 0.06,
      cx - armOuterW, elbowY,
    );
    body.quadraticBezierTo(
      cx - armOuterW, handY - h * 0.02,
      cx - armOuterW + armThick * 0.5, handY,
    );

    // Left arm – inner edge coming back up
    body.lineTo(cx - armOuterW + armThick * 1.8, handY);
    body.quadraticBezierTo(
      cx - armOuterW + armThick * 1.5, elbowY,
      cx - shoulderW + armThick, shoulderY + h * 0.06,
    );

    // Left torso side down to hip
    body.lineTo(cx - shoulderW + armThick, shoulderY + h * 0.06);
    body.quadraticBezierTo(
      cx - hipW - w * 0.02, torsoBottomY * 0.75,
      cx - hipW, torsoBottomY,
    );

    // Left hip to crotch
    body.quadraticBezierTo(
      cx - hipW + w * 0.01, crotchY,
      cx - legOuterW, crotchY,
    );

    // Left leg outer edge
    body.quadraticBezierTo(
      cx - legOuterW - w * 0.01, kneeY,
      cx - legBottomW - w * 0.04, kneeY,
    );
    body.lineTo(cx - legBottomW - w * 0.02, footY);

    // Left foot
    body.lineTo(cx - legBottomW + w * 0.06, footY);

    // Left leg inner edge going back up
    body.lineTo(cx - legInnerW + w * 0.02, kneeY);
    body.quadraticBezierTo(
      cx - legInnerW, crotchY + h * 0.02,
      cx - legInnerW, crotchY,
    );

    // Crotch centre
    body.quadraticBezierTo(cx, crotchY + h * 0.03, cx + legInnerW, crotchY);

    // Right leg inner edge
    body.quadraticBezierTo(
      cx + legInnerW, crotchY + h * 0.02,
      cx + legInnerW - w * 0.02, kneeY,
    );

    // Right foot
    body.lineTo(cx + legBottomW - w * 0.06, footY);
    body.lineTo(cx + legBottomW + w * 0.02, footY);

    // Right leg outer edge going back up
    body.lineTo(cx + legBottomW + w * 0.04, kneeY);
    body.quadraticBezierTo(
      cx + legOuterW + w * 0.01, kneeY,
      cx + legOuterW, crotchY,
    );

    // Right hip
    body.quadraticBezierTo(
      cx + hipW - w * 0.01, crotchY,
      cx + hipW, torsoBottomY,
    );

    // Right torso side up to shoulder
    body.quadraticBezierTo(
      cx + hipW + w * 0.02, torsoBottomY * 0.75,
      cx + shoulderW - armThick, shoulderY + h * 0.06,
    );

    // Right arm inner edge going down
    body.quadraticBezierTo(
      cx + armOuterW - armThick * 1.5, elbowY,
      cx + armOuterW - armThick * 1.8, handY,
    );

    // Right hand
    body.lineTo(cx + armOuterW - armThick * 0.5, handY);

    // Right arm outer edge going back up
    body.quadraticBezierTo(
      cx + armOuterW, handY - h * 0.02,
      cx + armOuterW, elbowY,
    );
    body.quadraticBezierTo(
      cx + armOuterW, shoulderY + h * 0.06,
      cx + shoulderW, shoulderY + h * 0.02,
    );

    // Right shoulder up to right side of neck
    body.lineTo(cx + neckW, shoulderY);
    body.lineTo(cx + neckW, neckTop);

    body.close();

    path.addPath(body, Offset.zero);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPath = _buildBodyPath(w, h);

    // -- Water fill clipped to body shape --
    final fillFraction = waterPercent / 100.0;
    // The fill rectangle rises from the bottom of the canvas.
    final fillTop = h * (1.0 - fillFraction);
    final fillRect = Rect.fromLTRB(0, fillTop, w, h);

    canvas.save();
    canvas.clipPath(bodyPath);
    final fillPaint = Paint()
      ..color = _fillColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(fillRect, fillPaint);
    canvas.restore();

    // -- Body outline --
    final outlinePaint = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) {
    return oldDelegate.waterPercent != waterPercent;
  }
}
