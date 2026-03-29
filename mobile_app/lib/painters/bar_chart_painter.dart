import 'package:flutter/material.dart';

class BarChartPainter extends CustomPainter {
  final List<int> data;
  final List<Color> colors;
  final List<String> labels;
  final Color textColor;
  final Color gridColor;

  BarChartPainter({
    required this.data,
    required this.colors,
    required this.labels,
    this.textColor = const Color(0xFF9E9E9E),
    this.gridColor = const Color(0xFFEEEEEE),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = (data.reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble();
    const labelHeight = 22.0;
    const topPadding = 28.0;
    const leftPadding = 22.0;
    const rightPadding = 16.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - labelHeight - topPadding;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid lines + Y-axis labels
    final step = (maxValue / 4).ceilToDouble();
    for (int i = 0; i <= 4; i++) {
      final val = (step * i).toInt();
      final y = topPadding + chartHeight * (1 - val / maxValue);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
      textPainter.text = TextSpan(
        text: val.toString(),
        style: TextStyle(color: textColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Bars
    final sectionWidth = chartWidth / data.length;
    final barWidth = sectionWidth * 0.35;

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

      

      // X-axis label
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: textColor, fontSize: 11),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}