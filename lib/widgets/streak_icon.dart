import 'package:flutter/material.dart';

/// A simple line-art coffee cup with steam wisps — the streak glyph. Keeps
/// the coffee theme (unlike a generic fire icon) while staying legible at
/// both the small top-bar pill size and the larger streak-sheet size.
class StreakIcon extends StatelessWidget {
  final double size;
  final Color color;

  const StreakIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CupSteamPainter(color: color),
    );
  }
}

class _CupSteamPainter extends CustomPainter {
  final Color color;
  const _CupSteamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyTop = h * 0.46;
    final left = w * 0.2;
    final right = w * 0.66;
    final bottom = h * 0.84;
    final taper = (bottom - bodyTop) * 0.22;

    final cupPath = Path()
      ..moveTo(left, bodyTop)
      ..lineTo(left + taper * 0.3, bottom - taper)
      ..quadraticBezierTo(left + taper * 0.4, bottom, (left + right) / 2, bottom)
      ..quadraticBezierTo(right - taper * 0.4, bottom, right - taper * 0.3, bottom - taper)
      ..lineTo(right, bodyTop);
    canvas.drawPath(cupPath, stroke);
    canvas.drawLine(Offset(left, bodyTop), Offset(right, bodyTop), stroke);

    final handleRect = Rect.fromLTRB(
      right - w * 0.03,
      bodyTop + h * 0.04,
      right + w * 0.24,
      bodyTop + h * 0.32,
    );
    canvas.drawArc(handleRect, -1.3, 2.6, false, stroke);

    final steamStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final steam1 = Path()
      ..moveTo(w * 0.34, h * 0.34)
      ..cubicTo(w * 0.24, h * 0.26, w * 0.42, h * 0.18, w * 0.36, h * 0.06);
    canvas.drawPath(steam1, steamStroke);

    final steam2 = Path()
      ..moveTo(w * 0.52, h * 0.34)
      ..cubicTo(w * 0.42, h * 0.26, w * 0.6, h * 0.18, w * 0.54, h * 0.06);
    canvas.drawPath(steam2, steamStroke);
  }

  @override
  bool shouldRepaint(covariant _CupSteamPainter oldDelegate) => oldDelegate.color != color;
}
