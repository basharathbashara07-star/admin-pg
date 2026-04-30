import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class AdminRewardsScreen extends StatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  State<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends State<AdminRewardsScreen> {
  String _token = '';
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _token = prefs.getString('token') ?? '');
    await _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/admin/rewards/leaderboard'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() => _leaderboard = List<Map<String, dynamic>>.from(data['leaderboard']));
      }
    } catch (e) {
      debugPrint('fetchLeaderboard error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adjustPoints(int tenantId, String tenantName) async {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Adjust Points — $tenantName',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter positive to add, negative to deduct.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText: 'Points (e.g. 10 or -5)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final points = int.tryParse(pointsController.text);
    if (points == null) return;

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/admin/rewards/adjust'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenant_id': tenantId,
          'points': points,
          'reason': reasonController.text.isEmpty ? 'Manual adjustment by admin' : reasonController.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points adjusted!'), backgroundColor: Colors.green),
        );
        await _fetchLeaderboard();
      }
    } catch (e) {
      debugPrint('adjustPoints error: $e');
    }
  }

  Future<void> _viewHistory(int tenantId, String tenantName) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/admin/rewards/history/$tenantId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] != true) return;
      final history = List<Map<String, dynamic>>.from(data['history']);

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('$tenantName — Points History',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('No history yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (_, i) {
                          final h = history[i];
                          final isEarned = h['type'] == 'earned';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isEarned
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              child: Text(
                                isEarned ? '+${h['points']}' : '-${h['points']}',
                                style: TextStyle(
                                  color: isEarned ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(h['reason'] ?? '', style: const TextStyle(fontSize: 13)),
                            subtitle: Text(_formatDate(h['created_at'] ?? ''),
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('viewHistory error: $e');
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _rankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700);
    if (index == 1) return const Color(0xFFC0C0C0);
    if (index == 2) return const Color(0xFFCD7F32);
    return const Color(0xFF2196F3);
  }

  String _rankEmoji(int index) {
    if (index == 0) return '🥇';
    if (index == 1) return '🥈';
    if (index == 2) return '🥉';
    return '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Tenant Rewards', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLeaderboard),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLeaderboard,
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rewards Leaderboard',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('${_leaderboard.length} active tenants',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // How points are earned info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Points auto-awarded: +10 on-time pay, +20 early (5+ days), +15 for 3-month streak',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Leaderboard
                  Expanded(
                    child: _leaderboard.isEmpty
                        ? const Center(
                            child: Text('No tenants yet.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _leaderboard.length,
                            itemBuilder: (context, index) {
                              final tenant = _leaderboard[index];
                              final rankColor = _rankColor(index);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: index < 3 ? rankColor.withOpacity(0.3) : Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: rankColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(_rankEmoji(index),
                                          style: const TextStyle(fontSize: 18)),
                                    ),
                                  ),
                                  title: Text(
                                    tenant['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    'Room ${tenant['room_no'] ?? '—'}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${tenant['reward_points'] ?? 0} pts',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: rankColor == const Color(0xFF2196F3)
                                                  ? const Color(0xFF2196F3)
                                                  : rankColor,
                                            ),
                                          ),
                                          const Text('points', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (val) {
                                          if (val == 'history') {
                                            _viewHistory(tenant['id'], tenant['name']);
                                          } else if (val == 'adjust') {
                                            _adjustPoints(tenant['id'], tenant['name']);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'history', child: Text('View History')),
                                          const PopupMenuItem(value: 'adjust', child: Text('Adjust Points')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}