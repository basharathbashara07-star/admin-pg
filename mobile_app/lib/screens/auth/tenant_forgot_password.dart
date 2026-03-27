import 'package:flutter/material.dart';
import 'tenant_otp_verify.dart';
import '../../services/api_service.dart'; // ✅ API calls

class TenantForgotPassword extends StatefulWidget {
  const TenantForgotPassword({super.key});

  @override
  State<TenantForgotPassword> createState() => _TenantForgotPasswordState();
}

class _TenantForgotPasswordState extends State<TenantForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false; // ✅ Loading flag

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 20),

              // Icon
              const Icon(
                Icons.lock_reset,
                size: 60,
                color: Colors.cyanAccent,
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Description
              const Text(
                "Enter your registered email.\nWe will send you an OTP to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 32),

              // Label
              _label("Email or Username"),

              const SizedBox(height: 8),

              // Input field
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter email",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.person_outline, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E2A38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Send OTP button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter your email")),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            final response = await ApiService.forgotPassword(email);

                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response['message'] ??
                                      "If an account with this email exists, you will recieve an OTP.",
                                ),
                              ),
                            );

                            // Navigate to OTP screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TenantOtpVerify(email: email),
                              ),
                            );
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
                  // ✅ Show spinner when loading
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Send OTP",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Back to login
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  "Back to Login",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Label widget
  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }
}