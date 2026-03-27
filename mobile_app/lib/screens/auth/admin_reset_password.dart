import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // ✅ For backend API
import '../../utils/password_validator.dart'; // ✅ For password rules

class AdminResetPassword extends StatefulWidget {
  final String email;

  const AdminResetPassword({super.key, required this.email});

  @override
  State<AdminResetPassword> createState() => _AdminResetPasswordState();
}

class _AdminResetPasswordState extends State<AdminResetPassword> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _passwordMessage = "";
  Color _passwordMessageColor = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.lock_outline,
                size: 60,
                color: Colors.cyanAccent,
              ),

              const SizedBox(height: 16),

              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Create a new password for\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 32),

              // New Password
              _passwordField(
                controller: _passwordController,
                hint: "New Password",
                obscure: _obscurePassword,
                toggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    final validationMsg = PasswordValidator.validate(value);
                    if (validationMsg != null) {
                      _passwordMessage = validationMsg;
                      _passwordMessageColor = Colors.red;
                    } else {
                      _passwordMessage = "Password looks good";
                      _passwordMessageColor = Colors.green;
                    }
                  });
                },
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _passwordMessage,
                  style: TextStyle(
                    color: _passwordMessageColor,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Password
              _passwordField(
                controller: _confirmController,
                hint: "Confirm Password",
                obscure: _obscureConfirm,
                toggle: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),

              const SizedBox(height: 28),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final password = _passwordController.text.trim();
                          final confirm = _confirmController.text.trim();

                          // Check if passwords match
                          if (password != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Passwords do not match")),
                            );
                            return;
                          }

                          // Validate password rules
                          final validationMsg =
                              PasswordValidator.validate(password);
                          if (validationMsg != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(validationMsg)),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            // Call backend API to reset password
                            final response = await ApiService.adminResetPassword(
                                widget.email, password);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['message'])),
                            );

                            if (response['success'] == true ||
                                response['status'] == 'success') {
                              // Password reset successful → go back to login
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }

                          setState(() => _isLoading = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Reset Password",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: const Color(0xFF1E2A38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}