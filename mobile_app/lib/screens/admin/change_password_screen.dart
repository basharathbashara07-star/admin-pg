import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  double _strength  = 0;
  String _strengthLabel = '';
  Color  _strengthColor = Colors.transparent;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String val) {
    double s = 0;
    if (val.length >= 8)                          s += 0.25;
    if (val.contains(RegExp(r'[A-Z]')))           s += 0.25;
    if (val.contains(RegExp(r'[0-9]')))           s += 0.25;
    if (val.contains(RegExp(r'[!@#\$%^&*]')))    s += 0.25;

    String label;
    Color  color;
    if (s <= 0.25) {
      label = 'Weak — add uppercase, numbers & symbols';
      color = const Color(0xFFF44336);
    } else if (s <= 0.5) {
      label = 'Fair — add numbers & symbols';
      color = const Color(0xFFFF9800);
    } else if (s <= 0.75) {
      label = 'Medium — add symbols to make it stronger';
      color = const Color(0xFFFF9800);
    } else {
      label = 'Strong — great password!';
      color = const Color(0xFF4CAF50);
    }

    setState(() {
      _strength      = s;
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  void _submit() {
    if (_currentCtrl.text.isEmpty) {
      _showSnack('Please enter your current password', isError: true);
      return;
    }
    if (_newCtrl.text.length < 8) {
      _showSnack('New password must be at least 8 characters',
          isError: true);
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _showSnack('Passwords do not match', isError: true);
      return;
    }
    // TODO: connect to backend
    _showSnack('Password updated successfully!');
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A1A2E), size: 20),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Lock icon ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Update your password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your current password to continue',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF9E9E9E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── Current Password ──
            _passwordField(
              label:      'Current Password',
              controller: _currentCtrl,
              show:       _showCurrent,
              onToggle:   () =>
                  setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 16),

            // ── New Password ──
            _passwordField(
              label:      'New Password',
              controller: _newCtrl,
              show:       _showNew,
              onToggle:   () =>
                  setState(() => _showNew = !_showNew),
              onChanged:  _checkStrength,
            ),
            const SizedBox(height: 10),

            // ── Strength bar ──
            if (_newCtrl.text.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _strength,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_strengthColor),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _strengthLabel,
                  style: TextStyle(
                      fontSize: 10, color: _strengthColor),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Confirm Password ──
            _passwordField(
              label:      'Confirm New Password',
              controller: _confirmCtrl,
              show:       _showConfirm,
              onToggle:   () =>
                  setState(() => _showConfirm = !_showConfirm),
            ),
            const SizedBox(height: 32),

            // ── Update button ──
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF2196F3).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Cancel ──
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6478BE),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: TextField(
            controller: controller,
            obscureText: !show,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  show
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF9E9E9E),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}