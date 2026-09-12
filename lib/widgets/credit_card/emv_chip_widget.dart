import 'package:flutter/material.dart';

class EmvChipWidget extends StatelessWidget {
  const EmvChipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE27D),
            Color(0xFFE5B53B),
            Color(0xFFCC9928),
            Color(0xFFE2C470),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFF9E781C).withValues(alpha: 0.65),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.2),
        child: CustomPaint(
          painter: ChipGridPainter(),
        ),
      ),
    );
  }
}

class ChipGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark etched groove paint
    final groovePaint = Paint()
      ..color = const Color(0xFF6B4E08).withValues(alpha: 0.7)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Light metallic highlight for engraved relief
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    void drawEngravedPath(Path p) {
      canvas.drawPath(p.shift(const Offset(0.35, 0.35)), highlightPaint);
      canvas.drawPath(p, groovePaint);
    }

    // Center contact island
    final centerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.5),
        width: w * 0.36,
        height: h * 0.44,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
        centerRect.shift(const Offset(0.35, 0.35)), highlightPaint);
    canvas.drawRRect(centerRect, groovePaint);

    final paths = Path();

    // Horizontal trace lines from center to edges
    paths.moveTo(0, h * 0.32);
    paths.lineTo(w * 0.30, h * 0.32);

    paths.moveTo(0, h * 0.68);
    paths.lineTo(w * 0.30, h * 0.68);

    paths.moveTo(w * 0.66, h * 0.32);
    paths.lineTo(w, h * 0.32);

    paths.moveTo(w * 0.66, h * 0.68);
    paths.lineTo(w, h * 0.68);

    // Vertical top/bottom trace lines
    paths.moveTo(w * 0.48, 0);
    paths.lineTo(w * 0.48, h * 0.28);

    paths.moveTo(w * 0.48, h * 0.72);
    paths.lineTo(w * 0.48, h);

    drawEngravedPath(paths);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
