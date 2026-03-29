import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/occupancy_card.dart';
import '../../widgets/rent_status_card.dart';
import '../../widgets/recent_activity_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'tenant_screen.dart';
import 'rent_screen.dart';
import 'maintenance_screen.dart';
import 'chat_list_screen.dart';
import 'room_details_screen.dart';
import 'profile_screen.dart';
import 'visitor_screen.dart';
import '../../services/api_service.dart';
import '../../main.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _adminName = 'Admin';
  String _pgName = 'PG';
  String _totalResidents = '0';
  String _vacantRooms = '0';
  String _pendingRent = '₹0';
  String _openTickets = '0';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchDashboardData();
    });
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('name') ?? 'Admin';
      _pgName = prefs.getString('pg_name') ?? 'PG';
    });
    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final data = await ApiService.fetchDashboardSummary(token);
      if (data['success'] == true) {
        final d = data['data'];
        setState(() {
          _totalResidents = d['total_residents'].toString();
          _vacantRooms = d['vacant_rooms'].toString();
          _pendingRent = '₹${double.parse(d['pending_rent'].toString()).toStringAsFixed(0)}';
          _openTickets = d['open_tickets'].toString();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _selectedIndex == 0 ? _buildDashboard() : _buildPlaceholder(),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Text(
            _pgName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, __) {
            final isDark = mode == ThemeMode.dark;
            return GestureDetector(
              onTap: () {
                themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                  color: isDark ? const Color(0xFF90CAF9) : const Color(0xFFFFC107),
                  size: 22,
                ),
              ),
            );
          },
        ),
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.notifications_rounded, color: Color(0xFF2196F3), size: 22),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Welcome Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back! 👋',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _adminName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your PG with ease',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Stat Cards ──
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.people_rounded,
                  iconBg: const Color(0xFF2196F3),
                  value: _totalResidents,
                  label: 'Total Residents',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.home_rounded,
                  iconBg: const Color(0xFF4CAF50),
                  value: _vacantRooms,
                  label: 'Vacant Rooms',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.receipt_rounded,
                  iconBg: const Color(0xFFFFC107),
                  value: _pendingRent,
                  label: 'Pending Rent',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.build_rounded,
                  iconBg: const Color(0xFFF44336),
                  value: _openTickets,
                  label: 'Open Tickets',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Quick Actions ──
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

         Row(
        children: [
       Expanded(child: _quickAction(Icons.meeting_room_rounded, 'Room\nDetails', const Color(0xFF2196F3), const Color(0xFFE3F2FD), () {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomDetailsScreen()));
       })),
       const SizedBox(width: 12),
       Expanded(child: _quickAction(Icons.people_alt_rounded, 'Visitor\nRequests', const Color(0xFF9C27B0), const Color(0xFFF3E5F5), () {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorScreen()));
      })),      
       const SizedBox(width: 12),
       Expanded(child: _quickAction(Icons.chat_rounded, 'Chat\n', const Color(0xFF00BCD4), const Color(0xFFE0F7FA), () {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
      })),
    ],
  ),
  const SizedBox(height: 20),

          // ── Charts ──
          SizedBox(
        height: 280,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(child: OccupancyCard()),
        SizedBox(width: 12),
        Expanded(child: RentStatusCard()),
     ],
   ),
),
          const SizedBox(height: 20),

          // ── Recent Activity ──
          const RecentActivityCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (_selectedIndex == 1) return const TenantScreen();
    if (_selectedIndex == 2) return const RentScreen();
    if (_selectedIndex == 3) return MaintenanceScreen();
    if (_selectedIndex == 4) return const ProfileScreen();

    return const Center(
      child: Text('Coming Soon', style: TextStyle(fontSize: 18, color: Color(0xFF9E9E9E))),
    );
  }
}