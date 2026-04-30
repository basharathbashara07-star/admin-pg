import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';

class AdminEmergencyScreen extends StatefulWidget {
  const AdminEmergencyScreen({super.key});

  @override
  State<AdminEmergencyScreen> createState() => _AdminEmergencyScreenState();
}

class _AdminEmergencyScreenState extends State<AdminEmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _alertController;
  late Animation<double> _alertAnimation;

  String _token = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _alerts = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadToken();

    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _alertAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _token = prefs.getString('admin_token') ?? '');
    await _fetchAlerts();

    // Poll every 10 seconds for new alerts
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAlerts();
    });
  }

  Future<void> _fetchAlerts() async {
    if (_token.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/emergency/alerts'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(data['alerts']);
        });

        // Flash animation if any active alert
        final hasActive = _alerts.any((a) => a['status'] == 'active');
        if (hasActive && !_alertController.isAnimating) {
          _alertController.repeat(reverse: true);
        } else if (!hasActive) {
          _alertController.stop();
          _alertController.reset();
        }
      }
    } catch (e) {
      debugPrint('fetchAlerts error: $e');
    }
  }

  Future<void> _resolveAlert(int alertId) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/emergency/resolve/$alertId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await _fetchAlerts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Alert marked as resolved'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('resolveAlert error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _alertController.dispose();
    super.dispose();
  }

  bool get _hasActiveAlerts =>
      _alerts.any((a) => a['status'] == 'active');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _hasActiveAlerts ? const Color(0xFFFEF2F2) : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor:
            _hasActiveAlerts ? const Color(0xFFFEF2F2) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Buzzer banner when active alerts exist
                  if (_hasActiveAlerts)
                    AnimatedBuilder(
                      animation: _alertAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _alertAnimation.value,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.danger.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.crisis_alert,
                                  color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                '🚨 EMERGENCY ALERT ACTIVE!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          _hasActiveAlerts
                              ? 'Active Alerts (${_alerts.where((a) => a['status'] == 'active').length})'
                              : 'All Clear',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _hasActiveAlerts
                                ? AppTheme.danger
                                : AppTheme.success,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${_alerts.length}',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textMid),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _alerts.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchAlerts,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: _alerts.length,
                              itemBuilder: (context, index) {
                                final alert = _alerts[index];
                                return _buildAlertCard(alert);
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 72, color: AppTheme.success.withOpacity(0.6)),
          const SizedBox(height: 16),
          const Text(
            'All Clear!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'No emergency alerts at the moment.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isActive = alert['status'] == 'active';
    final tenantName = alert['tenant_name'] ?? 'Unknown Tenant';
    final roomNumber = alert['room_number'] ?? '—';
    final message = alert['message'] ?? 'SOS Alert';
    final createdAt = alert['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFEE2E2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.danger.withOpacity(0.4)
              : Colors.grey.shade200,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppTheme.danger.withOpacity(0.1)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.danger
                        : AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? '🚨 ACTIVE' : '✅ Resolved',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppTheme.success,
                    ),
                  ),
                ),
                const Spacer(),
                if (createdAt.isNotEmpty)
                  Text(
                    _formatTime(createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMid),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppTheme.textMid),
                const SizedBox(width: 6),
                Text(
                  tenantName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined,
                    size: 16, color: AppTheme.textMid),
                const SizedBox(width: 6),
                Text(
                  'Room $roomNumber',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMid),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                  fontSize: 13,
                  color:
                      isActive ? AppTheme.danger : AppTheme.textMid,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
            ),
            if (isActive) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(
                    'Mark as Resolved',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _resolveAlert(alert['id']),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String rawTime) {
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return rawTime;
    }
  }
}