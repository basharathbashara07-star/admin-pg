import 'package:flutter/material.dart';
import 'dart:math' as math;

class DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color filledColor;
  final Color emptyColor;

  DonutChartPainter({
    required this.percentage,
    required this.filledColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final bgPaint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = filledColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fgPaint);

    // Gap notch for vacant section
    final vacantPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2;
    const gapAngle = 0.21;
    final gapStart = -math.pi / 2 + sweepAngle;
    canvas.drawArc(rect, gapStart, gapAngle, false, vacantPaint);

    final lightPaint = Paint()
      ..color = const Color(0xFFB2DFDB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, gapStart + 0.02, gapAngle - 0.02, false, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}