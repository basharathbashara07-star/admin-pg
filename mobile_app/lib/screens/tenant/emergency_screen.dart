import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _sosActivated = false;
  bool _isLoading = false;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadToken();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _token = prefs.getString('tenant_token') ?? '');
  }

  Future<void> _sendSOS() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/emergency/sos'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': 'SOS Alert triggered by tenant!'}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() => _sosActivated = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚨 SOS Alert Sent to Warden!'),
              backgroundColor: AppTheme.danger,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to send SOS'),
              backgroundColor: Colors.grey[700],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('sendSOS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Try again.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSOS() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/emergency/cancel'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() => _sosActivated = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Alert Cancelled'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('cancelSOS error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _confirmSOS() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('Activate SOS?', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'This will immediately alert the warden. Press Send SOS only in a real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              _sendSOS();
            },
            child: const Text(
              'Send SOS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        _sosActivated ? const Color(0xFFFEF2F2) : AppTheme.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Active alert banner
              if (_sosActivated) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.crisis_alert, color: AppTheme.danger, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🚨 SOS Active! Help is on the way.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.danger,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),
              const Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Press the SOS button below to immediately alert the warden.',
                style: TextStyle(fontSize: 14, color: AppTheme.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),

              // SOS Button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _sosActivated ? _pulseAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: _isLoading || _sosActivated ? null : _confirmSOS,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _sosActivated
                              ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]
                              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.danger.withOpacity(
                                _sosActivated ? 0.6 : 0.35),
                            blurRadius: _sosActivated ? 50 : 24,
                            spreadRadius: _sosActivated ? 12 : 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _sosActivated
                                      ? Icons.crisis_alert
                                      : Icons.sos,
                                  color: Colors.white,
                                  size: 72,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _sosActivated ? 'ACTIVE' : 'SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Cancel button (only when active)
              if (_sosActivated)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppTheme.textMid),
                    label: const Text(
                      'Cancel Alert',
                      style: TextStyle(
                          color: AppTheme.textMid, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.textMid),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _cancelSOS,
                  ),
                ),

              const SizedBox(height: 40),

              // Tips
              AppCard(
                color: const Color(0xFFFFF7ED),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Emergency Tips',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Stay calm and move to a safe area'),
                    _buildTip('Do not open doors if you smell smoke'),
                    _buildTip('Keep your phone charged for emergencies'),
                    _buildTip('Know your room number to report to authorities'),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppTheme.orange, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(tip,
                style:
                    const TextStyle(fontSize: 13, color: AppTheme.textMid)),
          ),
        ],
      ),
    );
  }
}