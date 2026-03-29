import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/phone_validator.dart';
class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String pgName;
  final String address;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.pgName,
    required this.address,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _pgNameCtrl;
  late final TextEditingController _addressCtrl;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl      = TextEditingController(text: widget.name);
    _emailCtrl     = TextEditingController(text: widget.email);
    _phoneCtrl     = TextEditingController(text: widget.phone);
    _pgNameCtrl    = TextEditingController(text: widget.pgName);
    _addressCtrl   = TextEditingController(text: widget.address);

    // Track changes
    for (final c in _allControllers) {
      c.addListener(() => setState(() => _hasChanges = true));
    }
  }

  List<TextEditingController> get _allControllers => [
        _nameCtrl, _emailCtrl, _phoneCtrl,
        _pgNameCtrl, _addressCtrl,
      ];

  @override
  void dispose() {
    for (final c in _allControllers) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
  if (_nameCtrl.text.trim().isEmpty) {
    _showSnack('Name cannot be empty', isError: true);
    return;
  }
  if (!_emailCtrl.text.contains('@')) {
    _showSnack('Please enter a valid email', isError: true);
    return;
  }
  final phoneError = PhoneValidator.validate(_phoneCtrl.text.trim());
  if (phoneError != null) {
  _showSnack(phoneError, isError: true);
  return;
 }

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final result = await ApiService.updateProfile(
      token,
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _pgNameCtrl.text.trim(),
      _addressCtrl.text.trim(),
    );

    if (result['success'] == true) {
      await prefs.setString('name', _nameCtrl.text.trim());
      await prefs.setString('email', _emailCtrl.text.trim());
      await prefs.setString('phone', _phoneCtrl.text.trim());
      await prefs.setString('pg_name', _pgNameCtrl.text.trim());
      await prefs.setString('pg_address', _addressCtrl.text.trim());

      if (mounted) {
        Navigator.pop(context, {
          'name':    _nameCtrl.text.trim(),
          'email':   _emailCtrl.text.trim(),
          'phone':   _phoneCtrl.text.trim(),
          'pgName':  _pgNameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
        });
        _showSnack('Profile updated successfully!');
      }
    } else {
      _showSnack(result['message'] ?? 'Update failed', isError: true);
    }
  } catch (e) {
    print('SAVE ERROR: $e');
    _showSnack('Server error', isError: true);
  }
}

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
      ),
    );
  }

  void _onBackPressed() {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        content: const Text(
            'You have unsaved changes. Are you sure you want to go back?',
            style: TextStyle(color: Color(0xFF9E9E9E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Editing',
                style: TextStyle(color: Color(0xFF2196F3),
                    fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: _onBackPressed,
          child: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A1A2E), size: 20),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _save,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 28),

            // ── Avatar ──────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF2196F3),
                    child: Text(
                      _nameCtrl.text
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap to change profile photo',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF2196F3)),
            ),
            const SizedBox(height: 28),

            // ── PERSONAL INFORMATION ─────────────────
            _sectionHeader('Personal Information'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _editField(
                    icon: '👤',
                    label: 'Full Name',
                    controller: _nameCtrl,
                    hint: 'Enter your full name',
                  ),
                  _divider(),
                  _editField(
                    icon: '✉',
                    label: 'Email',
                    controller: _emailCtrl,
                    hint: 'Enter your email',
                    keyboard: TextInputType.emailAddress,
                  ),
                  _divider(),
                  _editField(
                    icon: '📞',
                    label: 'Phone',
                    controller: _phoneCtrl,
                    hint: 'Enter your phone number',
                    keyboard: TextInputType.phone,
                    maxLength: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── PG DETAILS ───────────────────────────
            _sectionHeader('PG Details'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _editField(
                    icon: '🏠',
                    label: 'PG Name',
                    controller: _pgNameCtrl,
                    hint: 'Enter PG name',
                  ),
                  _divider(),
                  _editField(
                    icon: '📍',
                    label: 'Address',
                    controller: _addressCtrl,
                    hint: 'Enter full address',
                    maxLines: 2,
                  ),
                  
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Save Button ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  // ── WIDGETS ──────────────────────────────────

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 10),
      color: const Color(0xFFF8F9FA),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6478BE),
        ),
      ),
    );
  }

  Widget _editField({
    required String icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(icon,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                        color: Color(0xFFBDBDBD), fontSize: 12),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, color: Color(0xFFF5F5F5)),
      );
}