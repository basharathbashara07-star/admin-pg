import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RecentActivityCard extends StatefulWidget {
  const RecentActivityCard({super.key});

  @override
  State<RecentActivityCard> createState() => _RecentActivityCardState();
}

class _RecentActivityCardState extends State<RecentActivityCard> {
  bool _isLoading = true;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await ApiService.fetchRecentActivity(token);
      if (data['success'] == true) {
        setState(() {
          _activities = (data['activities'] as List).take(5).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'payment': return Icons.receipt_rounded;
      case 'overdue': return Icons.warning_rounded;
      case 'visitor': return Icons.person_add_rounded;
      case 'maintenance': return Icons.build_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconBg(String type) {
    switch (type) {
      case 'payment': return const Color(0xFF4CAF50);
      case 'overdue': return const Color(0xFFF44336);
      case 'visitor': return const Color(0xFF2196F3);
      case 'maintenance': return const Color(0xFFFF9800);
      default: return const Color(0xFF2196F3);
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_activities.isEmpty)
            const Text('No recent activity',
                style: TextStyle(color: Colors.grey))
          else
            ..._activities.map((a) => _buildActivityRow(context, a)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, dynamic item) {
    final type = item['type'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getIconBg(type),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIcon(type), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['message'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            _formatTime(item['time']?.toString()),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}