import 'package:flutter/material.dart';
import 'admin_login.dart';
import '../../utils/password_validator.dart';
import '../../utils/phone_validator.dart';
import '../../services/api_service.dart'; // make sure this exists

class RegisterPG extends StatefulWidget {
  const RegisterPG({super.key});

  @override
  State<RegisterPG> createState() => _RegisterPGState();
}

class _RegisterPGState extends State<RegisterPG> {
  // 🔥 Controllers Added
  final TextEditingController pgNameController = TextEditingController();
  final TextEditingController registerNoController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String passwordMessage = ""; // Dynamic message below password field
  Color passwordMessageColor = Colors.red;

  String confirmPasswordMessage = ""; // Dynamic message below confirm password
  Color confirmPasswordMessageColor = Colors.red;

  String _phoneMessage = ""; // Dynamic phone message
  Color _phoneMessageColor = Colors.red;

  @override
  void initState() {
    super.initState();

    // ✅ Password validation listener
    passwordController.addListener(() {
      final validationMessage = PasswordValidator.validate(passwordController.text);
      setState(() {
        if (validationMessage != null) {
          passwordMessage = validationMessage;
          passwordMessageColor = Colors.red;
        } else {
          passwordMessage = "Password meets all criteria ✅";
          passwordMessageColor = Colors.green;
        }

        if (confirmPasswordController.text.isNotEmpty) {
          if (passwordController.text == confirmPasswordController.text) {
            confirmPasswordMessage = "Passwords match ✅";
            confirmPasswordMessageColor = Colors.green;
          } else {
            confirmPasswordMessage = "Passwords do not match ❌";
            confirmPasswordMessageColor = Colors.red;
          }
        }
      });
    });

    // ✅ Confirm password listener
    confirmPasswordController.addListener(() {
      setState(() {
        if (confirmPasswordController.text == passwordController.text) {
          confirmPasswordMessage = "Passwords match ✅";
          confirmPasswordMessageColor = Colors.green;
        } else {
          confirmPasswordMessage = "Passwords do not match ❌";
          confirmPasswordMessageColor = Colors.red;
        }
      });
    });

    // ✅ Phone number listener
    phoneController.addListener(() {
      String digitsOnly = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length > 10) digitsOnly = digitsOnly.substring(0, 10);

      // Keep cursor at the end
      if (digitsOnly != phoneController.text) {
        phoneController.text = digitsOnly;
        phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: phoneController.text.length),
        );
      }

      setState(() {
        if (digitsOnly.isNotEmpty && digitsOnly.length < 10) {
          _phoneMessage = "Phone number must be 10 digits";
          _phoneMessageColor = Colors.red;
        } else {
          _phoneMessage = ""; // hide message if valid
        }
      });
    });
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white54),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF1E2A38),
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // 🔥 Register Function
  void registerPG() async {
    String digitsOnly = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneError = PhoneValidator.validate(digitsOnly);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneError)),
      );
      return;
    }

    final passwordError = PasswordValidator.validate(passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    final response = await ApiService.registerAdmin(
      registerNoController.text.trim(),
      ownerNameController.text.trim(),
      emailController.text.trim(),
      digitsOnly, // only phone number, no +91
      passwordController.text.trim(),
      pgNameController.text.trim(),
      addressController.text.trim(),
      cityController.text.trim(),
    );

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registered Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLogin()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Register PG",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Register Your PG",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Create an account to manage your property",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),

              // PG Details
              const Text(
                "PG Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pgNameController,
                decoration: _inputDecoration(
                  hint: "Enter PG Name",
                  icon: Icons.home_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerNoController,
                decoration: _inputDecoration(
                  hint: "Enter Registration No",
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: _inputDecoration(
                  hint: "Enter Address",
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: _inputDecoration(
                  hint: "Enter City",
                  icon: Icons.location_city_outlined,
                ),
              ),
              const SizedBox(height: 24),

              // Owner Details
              const Text(
                "Owner Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerNameController,
                decoration: _inputDecoration(
                  hint: "Enter owner name",
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: _inputDecoration(
                  hint: "Enter email",
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 12),

              // 🔥 Phone field without +91
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: "Enter 10-digit phone number",
                  icon: Icons.phone_outlined,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                _phoneMessage,
                style: TextStyle(color: _phoneMessageColor),
              ),
              const SizedBox(height: 24),

              // Security
              const Text(
                "Security",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: _inputDecoration(
                  hint: "Enter password",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                passwordMessage,
                style: TextStyle(color: passwordMessageColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: _inputDecoration(
                  hint: "Enter confirm password",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                confirmPasswordMessage,
                style: TextStyle(color: confirmPasswordMessageColor),
              ),
              const SizedBox(height: 20),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: registerPG,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    "Register PG",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLogin(),
                      ),
                    );
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}