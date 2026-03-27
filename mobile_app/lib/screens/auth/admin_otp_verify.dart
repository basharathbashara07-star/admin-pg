import 'package:flutter/material.dart';
import 'admin_reset_password.dart'; // ✅ Make sure this file exists
import '../../services/api_service.dart'; // ✅ Add this import for API calls

class AdminOtpVerify extends StatefulWidget {
  final String email;
  const AdminOtpVerify({super.key, required this.email});

  @override
  State<AdminOtpVerify> createState() => _AdminOtpVerifyState();
}

class _AdminOtpVerifyState extends State<AdminOtpVerify> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

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
                Icons.mark_email_read_outlined,
                size: 60,
                color: Colors.cyanAccent,
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                "An OTP has been sent to\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 32),

              // OTP Label
              _label("Enter OTP"),

              const SizedBox(height: 8),

              // OTP Input
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

              // Verify OTP Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final otp = _otpController.text.trim();

                          if (otp.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please enter a valid OTP")),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            // Call backend API to verify OTP
                            final response = await ApiService.verifyAdminOtp(
                                widget.email, otp);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['message'])),
                            );

                            if (response['status'] == 'success') {
                              // OTP verified → navigate to reset password
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminResetPassword(email: widget.email),
                                ),
                              );
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
                          "Verify OTP",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Resend OTP
              TextButton(
                onPressed: () {},
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