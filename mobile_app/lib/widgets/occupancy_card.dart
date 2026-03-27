import 'package:flutter/material.dart';
import '../painters/donut_chart_painter.dart';

class OccupancyCard extends StatelessWidget {
  const OccupancyCard({super.key});

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
            'Occupancy Rate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: DonutChartPainter(
                  percentage: 77.8,
                  filledColor: const Color(0xFF4CAF50),
                  emptyColor: const Color(0xFFE0E0E0),
                ),
                child: Center(
                  child: Text(
                    '77.8%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendRow(context,const Color(0xFF4CAF50), '36 Occupied'),
          const SizedBox(height: 6),
          _buildLegendRow(context,const Color(0xFFE0E0E0), '12 Vacant'),
        ],
      ),
    );
  }

  Widget _buildLegendRow(BuildContext context,Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style:  TextStyle(
            fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}