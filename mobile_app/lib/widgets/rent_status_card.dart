import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../painters/bar_chart_painter.dart';
import '../services/api_service.dart';

class RentStatusCard extends StatefulWidget {
  const RentStatusCard({super.key});

  @override
  State<RentStatusCard> createState() => _RentStatusCardState();
}

class _RentStatusCardState extends State<RentStatusCard> {
  bool _isLoading = true;
  List<double> _data = [0, 0, 0]; // paid, due, overdue

  @override
  void initState() {
    super.initState();
    _fetchRentStatus();
  }

  Future<void> _fetchRentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final data = await ApiService.fetchRentSummary(token);

      if (data['success'] == true) {
        final d = data['data'];
        if (mounted) {
          setState(() {
            _data = [
              (d['paid'] ?? 0).toDouble(),
              (d['due'] ?? 0).toDouble(),
              (d['overdue'] ?? 0).toDouble(),
            ];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}