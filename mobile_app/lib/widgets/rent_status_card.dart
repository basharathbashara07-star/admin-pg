import 'package:flutter/material.dart';
import '../painters/bar_chart_painter.dart';

class RentStatusCard extends StatelessWidget {
  const RentStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rent Status Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: BarChartPainter(
                data: const [8, 4, 2],
                colors: const [
                  Color(0xFF4CAF50),
                  Color(0xFFFFC107),
                  Color(0xFFF44336),
                ],
                labels: const ['Paid', 'Due', 'Overdue'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}