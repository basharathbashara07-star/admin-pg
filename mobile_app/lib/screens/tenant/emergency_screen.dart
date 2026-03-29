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

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {

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
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
      if (data['success']) {
        setState(() => _sosActivated = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚨 SOS Alert Sent to Warden & Security!'),
              backgroundColor: AppTheme.danger,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('sendSOS error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sosActivated ? const Color(0xFFFEF2F2) : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: _sosActivated ? const Color(0xFFFEF2F2) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
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
                      Icon(Icons.warning_amber, color: AppTheme.danger, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SOS Alert Sent! Help is on the way.',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.danger, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('Need Help?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text(
                'Press the SOS button to alert warden and security immediately.',
                style: TextStyle(fontSize: 14, color: AppTheme.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // BIG SOS BUTTON
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _sosActivated ? _pulseAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _activateSOS(context),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _sosActivated
                              ? [const Color(0xFFB91C1C), const Color(0xFFEF4444)]
                              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.danger.withOpacity(0.5),
                            blurRadius: _sosActivated ? 40 : 20,
                            spreadRadius: _sosActivated ? 10 : 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _sosActivated ? Icons.crisis_alert : Icons.sos,
                                  color: Colors.white,
                                  size: 70,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _sosActivated ? 'ACTIVE' : 'SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (_sosActivated) ...[
                PrimaryButton(
                  text: 'Cancel Alert',
                  onTap: () => setState(() => _sosActivated = false),
                  color: AppTheme.textMid,
                ),
                const SizedBox(height: 16),
              ],

              // Quick actions
              Row(
                children: [
                  Expanded(child: _buildEmergencyAction(context, Icons.call, 'Call Warden', 'Immediate', AppTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEmergencyAction(context, Icons.security, 'Call Security', 'On-site', AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildEmergencyAction(context, Icons.location_on, 'Share Location', 'Live GPS', AppTheme.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEmergencyAction(context, Icons.medical_services, 'Ambulance', 'Medical', AppTheme.danger)),
                ],
              ),
              const SizedBox(height: 24),

              // Tips
              AppCard(
                color: const Color(0xFFFFF7ED),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 Emergency Tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
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

  Widget _buildEmergencyAction(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title initiated...'), backgroundColor: color),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
          ],
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
          const Text('•  ', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700)),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppTheme.textMid))),
        ],
      ),
    );
  }

  void _activateSOS(BuildContext context) {
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
        content: const Text('This will immediately alert the warden and security. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              _sendSOS(); // calls real API!
            },
            child: const Text('Send SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}