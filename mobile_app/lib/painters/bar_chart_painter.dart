import 'package:flutter/material.dart';

class BarChartPainter extends CustomPainter {
  final List<int> data;
  final List<Color> colors;
  final List<String> labels;

  BarChartPainter({
    required this.data,
    required this.colors,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const maxValue = 8;
    const labelHeight = 22.0;
    const topPadding = 16.0;
    const leftPadding = 22.0;
    const rightPadding = 4.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - labelHeight - topPadding;

    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid lines + Y-axis labels
    for (final val in [0, 2, 4, 6, 8]) {
      final y = topPadding + chartHeight * (1 - val / maxValue);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
      textPainter.text = TextSpan(
        text: val.toString(),
        style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Bars
    final sectionWidth = chartWidth / data.length;
    final barWidth = sectionWidth * 0.52;

    for (int i = 0; i < data.length; i++) {
      final barHeight = chartHeight * data[i] / maxValue;
      final x = leftPadding + sectionWidth * i + (sectionWidth - barWidth) / 2;
      final y = topPadding + chartHeight - barHeight;

      // Bar body
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        Paint()..color = colors[i],
      );

      // Value on top of bar
      textPainter.text = TextSpan(
        text: data[i].toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y + 5),
      );

      // X-axis label
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - textPainter.width / 2,
          topPadding + chartHeight + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}