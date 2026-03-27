import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // ✅ ADD THIS
import 'tenant_reset_password.dart';

class TenantOtpVerify extends StatefulWidget {
  final String email;
  const TenantOtpVerify({
    super.key,
    required this.email,
  });

  @override
  State<TenantOtpVerify> createState() => _TenantOtpVerifyState();
}

class _TenantOtpVerifyState extends State<TenantOtpVerify> {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false; // ✅ ADD THIS

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

              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 20),

              const Icon(
                Icons.mark_email_read_outlined,
                size: 60,
                color: Colors.cyanAccent,
              ),

              const SizedBox(height: 16),

              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "An OTP has been sent to\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 32),

              _label("Enter OTP"),

              const SizedBox(height: 8),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "6-digit OTP",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E2A38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_otpController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a valid OTP"),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            final response =
                                await ApiService.verifyOtp(
                              widget.email,
                              _otpController.text.trim(),
                            );

                            // Show the backend message
                            final message =
                                response['message'] ?? "OTP Verified";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );

                            await Future.delayed(
                                const Duration(seconds: 2));

                            // ✅ Navigate to reset password page after verification
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TenantResetPassword(
                                  email: widget.email,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll(
                                      "Exception: ", ""),
                                ),
                              ),
                            );
                          }

                          setState(() {
                            _isLoading = false;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                        )
                      : const Text(
                          "Verify OTP",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "OTP has been resent to your registered email",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Resend OTP",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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