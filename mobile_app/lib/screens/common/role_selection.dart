import 'package:flutter/material.dart';

// ONLY tenant login is needed
import '../auth/tenant_login.dart';
import '../auth/admin_login.dart';

class RoleSelection extends StatelessWidget {
  const RoleSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // App Icon
                const Icon(
                  Icons.home_work_rounded,
                  size: 80,
                  color: Colors.cyanAccent,
                ),

                const SizedBox(height: 16),

                const Text(
                  "Livexa",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Smart Livin Simplifie",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 40),

                const Text(
                  "SELECT YOUR ROLE TO CONTINUE",
                  style: TextStyle(
                    color: Colors.white60,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 24),

                // TENANT CARD (CLICKABLE)
                _roleCard(
                  context,
                  title: "Tenant",
                  subtitle:
                      "Login with credentials provided by your PG owner",
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TenantLogin(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ADMIN CARD (DISABLED)
                _roleCard(
                  context,
                  title: "Admin / Owner",
                  subtitle: "Manage your PG, tenants, and operations",
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLogin(),
                        )
                    );
                  }, 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable role card
  Widget _roleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A38),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.cyan.withOpacity(0.2),
              child: Icon(icon, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}