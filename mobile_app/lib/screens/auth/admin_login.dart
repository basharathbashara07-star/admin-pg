import 'package:flutter/material.dart';
import 'register_pg.dart';
import 'admin_forgot_password.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/dashboard_screen.dart';



class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
         

  Future<void> _loginAdmin() async {
  final String email = _emailController.text.trim();
  final String password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter email and password")),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse("http://192.168.1.6:5000/api/admin/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
                     // 👇 ADD THIS - Save token and admin info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token'] ?? '');
      await prefs.setInt('admin_id', data['admin_id'] ?? 0);
      await prefs.setInt('pg_id', data['pg_id'] ?? 0);
      await prefs.setString('name', data['name'] ?? '');
      await prefs.setString('email', data['email'] ?? '');
      await prefs.setString('phone', data['phone'] ?? '');
      await prefs.setString('pg_name', data['pg_name'] ?? '');
      await prefs.setString('pg_address', data['address'] ?? '');

      print("TOKEN SAVED: ${data['token']}");
      print("Admin ID: ${data["admin_id"]}");
      print("PG ID: ${data["pg_id"]}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );

      
      
      // Next step we navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Login failed")),
      );
    }
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Server error")),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Back Arrow
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 20),

              // Shield Icon
              const Icon(
                Icons.shield_outlined,
                size: 70,
                color: Colors.cyanAccent,
              ),

              const SizedBox(height: 16),

              const Text(
                "Admin Login",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Login to manage your PG property",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              // Email
              _inputLabel("Email"),
              _inputField(
                hint: "Enter your email",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),

              const SizedBox(height: 16),

              // Password
              _inputLabel("Password"),
              _inputField(
                hint: "Enter your password",
                icon: Icons.lock_outline,
                controller: _passwordController,
                isPassword: true,
              ),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loginAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Forgot password
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminForgotPassword(),
                    ),
                  );
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),

              const SizedBox(height: 12),

              // Divider text
              const Text(
                "New PG Owner?",
                style: TextStyle(color: Colors.white60),
              ),

              const SizedBox(height: 12),

              // Register New PG button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPG(),
                    ),
                  );

                  
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.cyanAccent),
                  foregroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text("Register New PG"),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // -------- helpers --------

  Widget _inputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}