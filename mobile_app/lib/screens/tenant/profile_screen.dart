import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';
import '../auth/tenant_login.dart';
import 'chat_screen.dart';
import 'rewards_screen.dart';
import 'emergency_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {


  String token = '';
  Map<String, dynamic> tenantData = {};
  List<dynamic> roommates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('tenant_token') ?? '';
    await _fetchProfile();
    await _fetchRoommates();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => tenantData = data['data']);
      }
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRoommates() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses/roommates'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => roommates = data['data']['roommates'] ?? []);
      }
    } catch (e) {
      debugPrint('fetchRoommates error: $e');
    }
  }

  Future<void> _logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('tenant_token');
  if (mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TenantLogin()),
      (route) => false,
    );
  }
}

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name     = tenantData['name']    ?? 'Loading...';
    final roomNo   = tenantData['room_no'] ?? '';
    final pgName   = tenantData['pg_name'] ?? '';
    final email    = tenantData['email']   ?? '';
    final phone    = tenantData['phone']   ?? '';
    final checkIn  = _formatDate(tenantData['check_in_date']);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTokenAndFetch,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Profile Header ──
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AvatarWidget(name: name, size: 60),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                                    Text('Room $roomNo • $pgName', style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
                                      child: const Text('Active Tenant', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildProfileStat(roomNo.isEmpty ? '—' : roomNo, 'Room No.'),
                              _buildProfileStat(pgName.isEmpty ? '—' : pgName, 'PG Name'),
                              _buildProfileStat(checkIn, 'Move-in'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Menu ──
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildMenuItem(context, Icons.person_outlined, 'Personal Info', AppTheme.primary,
                              () => _showPersonalInfo(context, name, email, phone, checkIn)),
                          _buildDivider(),
                          _buildMenuItem(context, Icons.contact_phone_outlined, 'Emergency Contacts', AppTheme.danger,
                              () => _showEmergencyContacts(context, phone)),
                          _buildDivider(),
                          _buildMenuItem(context, Icons.group_outlined, 'Roommates', AppTheme.secondary,
                              () => _showRoommates(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildMenuItem(context, Icons.chat_outlined, 'Chat', AppTheme.primary, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                          }),
                          _buildDivider(),
                          _buildMenuItem(context, Icons.star_outlined, 'Rewards & Badges', AppTheme.warning, () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
                          }),
                          _buildDivider(),
                          _buildMenuItem(context, Icons.sos_outlined, 'Emergency SOS', AppTheme.danger, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildMenuItem(context, Icons.help_outline, 'Help & Support', AppTheme.textMid, () {}),
                          _buildDivider(),
                          _buildMenuItem(
                            context, Icons.logout, 'Logout', AppTheme.danger,
                            () => _showLogoutDialog(context),
                            textColor: AppTheme.danger,
                          ),
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

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
      ],
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 56);

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor ?? AppTheme.textDark)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
    );
  }

  // ── Personal Info Bottom Sheet ──
  void _showPersonalInfo(BuildContext context, String name, String email, String phone, String checkIn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _buildInfoRow('Full Name', name),
            _buildInfoRow('Email', email),
            _buildInfoRow('Phone', phone.isEmpty ? 'Not provided' : phone),
            _buildInfoRow('Move-in Date', checkIn),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Close', onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMid))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  // ── Emergency Contacts ──
  void _showEmergencyContacts(BuildContext context, String phone) {
  final fatherName  = tenantData['father_name']  ?? '';
  final fatherPhone = tenantData['father_phone'] ?? '';
  final motherName  = tenantData['mother_name']  ?? '';
  final motherPhone = tenantData['mother_phone'] ?? '';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      padding: const EdgeInsets.all(24), 
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Emergency Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _buildContactCard('My Phone', phone.isEmpty ? 'Not set' : phone, '📱'),
            const SizedBox(height: 10),
            _buildContactCard(
              fatherName.isEmpty ? 'Father' : fatherName,
              fatherPhone.isEmpty ? 'Not set' : fatherPhone,
              '👨'
            ),
            const SizedBox(height: 10),
            _buildContactCard(
              motherName.isEmpty ? 'Mother' : motherName,
              motherPhone.isEmpty ? 'Not set' : motherPhone,
              '👩'
            ),
            const SizedBox(height: 10),
            _buildContactCard('Admin / Warden', 'Contact via Chat', '👤'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildContactCard(String name, String phone, String emoji) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Roommates ──
  void _showRoommates(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Roommates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),


           if (roommates.isEmpty)
              const Center(child: Text('No roommates found', style: TextStyle(color: AppTheme.textMid)))
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: roommates.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                        child: Row(
                          children: [
                            AvatarWidget(name: r['name'] ?? '', size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                                  Text(r['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Logout ──
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}