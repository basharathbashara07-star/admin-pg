import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import '../common/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name      = 'Admin Kumar';
  String _email     = 'admin@greenviewpg.com';
  String _phone     = '+91 98765 43210';
  String _pgName    = 'GreenView PG';
  String _address   = '12, MG Road, Bangalore - 560001';
  String _pgContact = '+91 80123 45678';

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF9E9E9E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false);
              }
            },
            child: const Text('Logout',
                style: TextStyle(
                    color: Color(0xFFF44336),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _goToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name:      _name,
          email:     _email,
          phone:     _phone,
          pgName:    _pgName,
          address:   _address,
          pgContact: _pgContact,
        ),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        _name      = result['name']      ?? _name;
        _email     = result['email']     ?? _email;
        _phone     = result['phone']     ?? _phone;
        _pgName    = result['pgName']    ?? _pgName;
        _address   = result['address']   ?? _address;
        _pgContact = result['pgContact'] ?? _pgContact;
      });
    }
  }
                       
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? _name;
      _email = prefs.getString('email') ?? _email;
      _phone = prefs.getString('phone') ?? _phone;
      _pgName = prefs.getString('pg_name') ?? _pgName;
      _address = prefs.getString('pg_address') ?? _address;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── FIX: Wrap in Container for background color ──
    return Container(
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildAvatar(),
            const SizedBox(height: 14),

            Text(
              _name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              'Administrator',
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 4),

            Text(
              _email,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6478BE)),
            ),
            const SizedBox(height: 20),

            // ── Edit + Password buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _outlineBtn('✎   Edit Profile',
                        onTap: _goToEdit),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _outlineBtn('🔒  Password',
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ChangePasswordScreen()),
                            )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Personal Information ──
            _sectionHeader('Personal Information'),
            _listItem('👤', 'Full Name', _name),
            _listItem('✉',  'Email',     _email),
            _listItem('📞', 'Phone',     _phone),
            const SizedBox(height: 8),

            // ── PG Details ──
            _sectionHeader('PG Details'),
            _listItem('🏠', 'PG Name',    _pgName),
            _listItem('📍', 'Address',    _address),
            _listItem('📞', 'PG Contact', _pgContact),
            const SizedBox(height: 8),

            // ── Security ──
            _sectionHeader('Security'),
            _listItem('🔒', 'Password', 'Change →',
                valueColor: const Color(0xFF2196F3),
                onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ChangePasswordScreen()),
                    )),
            const SizedBox(height: 16),

            // ── Logout ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFF44336).withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      '🚪   Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF44336),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF2196F3), width: 3),
          ),
        ),
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFF2196F3),
          child: Text(
            _name.split(' ').map((e) => e[0]).take(2).join(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: _goToEdit,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          _statItem('14', 'Rooms'),
          _statDivider(),
          _statItem('8',  'Active'),
          _statDivider(),
          _statItem('42', 'Resolved'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1, height: 36, color: const Color(0xFFF0F0F0));

  Widget _outlineBtn(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6)
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFFF8F9FA),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6478BE))),
    );
  }

  Widget _listItem(String icon, String label, String value,
      {Color? valueColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E))),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ?? const Color(0xFF1A1A2E))),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: Color(0xFFE0E0E0), size: 18),
          ],
        ),
      ),
    );
  }
}