import 'dart:math' as math;
import 'package:flutter/material.dart';

class ContactlessWavesWidget extends StatelessWidget {
  final Color color;

  const ContactlessWavesWidget({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: ContactlessWavesPainter(color: color),
    );
  }
}

class ContactlessWavesPainter extends CustomPainter {
  final Color color;

  const ContactlessWavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.05, size.height * 0.5);
    const sweep = math.pi * 0.45;
    const start = -sweep / 2;

    for (int i = 1; i <= 3; i++) {
      final radius = 2.8 + (i * 3.6);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ContactlessWavesPainter oldDelegate) =>
      oldDelegate.color != color;
}
