import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../painters/bar_chart_painter.dart';
import 'dart:async';
import '../services/api_service.dart';

class RentStatusCard extends StatefulWidget {
  const RentStatusCard({super.key});

  @override
  State<RentStatusCard> createState() => _RentStatusCardState();
}

class _RentStatusCardState extends State<RentStatusCard> {
  bool _isLoading = true;
  List<int> _data = [0, 0, 0]; // paid, due, overdue
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchRentStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (_){
      _fetchRentStatus();
    });
  }


    Future<void> _fetchRentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final data = await ApiService.fetchRentSummary(token);

      if (data['success'] == true) {
        final rentStatus = data['rent_status'];
        if (mounted) {
          setState(() {
            _data = [
              (rentStatus['paid'] ?? 0).toInt(),
              (rentStatus['due'] ?? 0).toInt(),
              (rentStatus['overdue'] ?? 0).toInt(),
            ];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('RENT ERROR: $e');
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
            'Rent Status Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
  Expanded(
    child: Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            
            painter: BarChartPainter(
            data: _data,
            colors: const [
            Color(0xFF4CAF50),
            Color(0xFFFFC107),
            Color(0xFFF44336),
          ],
          labels: const ['Paid', 'Due', 'Overdue'],
          textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          gridColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.white24 
          : const Color(0xFFEEEEEE),
        ),
          ),
        ),
        const SizedBox(height: 8),
        _buildPercentRow(),
      ],
    ),
  ),
        ],
      ),
    );
  }

  Widget _buildPercentRow() {
  final total = _data.reduce((a, b) => a + b);
  final colors = [const Color(0xFF4CAF50), const Color(0xFFFFC107), const Color(0xFFF44336)];
  final labels = ['Paid', 'Due', 'Ovrd'];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: List.generate(3, (i) {
      final percent = total > 0 ? (_data[i] / total * 100).toStringAsFixed(0) : '0';
      return Column(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
          const SizedBox(height: 2),
          Text('${_data[i]}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF757575))),
          Text(labels[i], style: const TextStyle(fontSize: 8, color: Color(0xFF9E9E9E))),
        ],
      );
    }),
  );
}
}