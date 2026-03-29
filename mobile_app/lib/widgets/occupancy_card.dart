import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../painters/donut_chart_painter.dart';
import '../services/api_service.dart';

class OccupancyCard extends StatefulWidget {
  const OccupancyCard({super.key});

  @override
  State<OccupancyCard> createState() => _OccupancyCardState();
}

class _OccupancyCardState extends State<OccupancyCard> {
  bool _isLoading = true;
  int _occupied = 0;
  int _vacant = 0;
  double _percentage = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchOccupancy();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
    _fetchOccupancy();
  });
  }

  Future<void> _fetchOccupancy() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final data = await ApiService.fetchOccupancySummary(token);

    if (data['success'] == true) {
      if (mounted) {
        setState(() {
          _occupied = data['occupied'];
          _vacant = data['vacant'];
          _percentage = data['percentage'].toDouble();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  } catch (e) {
    print('OCCUPANCY ERROR: $e');
    if (mounted) setState(() => _isLoading = false);
  }
}
  
  @override
  void dispose() {
  _timer.cancel();
  super.dispose();
}
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
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    percentage: _percentage,
                    filledColor: const Color(0xFF4CAF50),
                    emptyColor: const Color(0xFFE0E0E0),
                  ),
                  child: Center(
                    child: Text(
                      '$_percentage%',
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
            _buildLegendRow(context, const Color(0xFF4CAF50), '$_occupied Occupied'),
            const SizedBox(height: 6),
            _buildLegendRow(context, const Color(0xFFE0E0E0), '$_vacant Vacant'),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendRow(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}