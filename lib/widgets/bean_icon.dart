import 'package:flutter/material.dart';

/// The coffee-bean glyph used for ratings and badges — an oval with a curved
/// center crease, matching the prototype's inline SVG `<symbol id="bean">`.
class BeanIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;

  const BeanIcon({super.key, required this.size, required this.color, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: filled ? 1 : 0.3,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BeanPainter(color: color),
      ),
    );
  }
}

class _BeanPainter extends CustomPainter {
  final Color color;
  const _BeanPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(rect.deflate(size.width * 0.04), fillPaint);
    canvas.drawOval(rect.deflate(size.width * 0.04), strokePaint);

    final crease = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.32, size.height * 0.5,
        size.width * 0.5, size.height * 0.92,
      );
    canvas.drawPath(crease, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BeanPainter oldDelegate) => oldDelegate.color != color;
}

/// A row of 5 beans reflecting a 0-5 rating.
class BeanRatingDisplay extends StatelessWidget {
  final int rating;
  final double size;
  final Color color;

  const BeanRatingDisplay({
    super.key,
    required this.rating,
    this.size = 13,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: BeanIcon(size: size, color: color, filled: i < rating),
        ),
      ),
    );
  }
}

/// Tappable 1-5 bean picker for the entry form. Tapping the already-selected
/// bean clears the rating back to 0, same as the prototype.
class BeanRatingPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double size;
  final Color color;

  const BeanRatingPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 24,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => onChanged(rating == n ? 0 : n),
            child: BeanIcon(size: size, color: color, filled: n <= rating),
          ),
        );
      }),
    );
  }
}
