import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tenant_app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';
import 'rent_screen.dart';
import 'maintenance_screen.dart';
import 'visitors_screen.dart';
import 'chat_screen.dart';
import 'emergency_screen.dart';




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
 String _token = '';

  List<Map<String, dynamic>> _autoAlerts = [];
  List<Map<String, dynamic>> _notices = [];
  bool _loadingNotices = true;
  int _currentNoticeIndex = 0;

  List<Map<String, dynamic>> _recentPayments = [];
  bool _loadingPayments = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _token = prefs.getString('tenant_token') ?? '');
    await _fetchNotices();
    await _fetchRecentPayments();
  }

  Future<void> _fetchRecentPayments() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/rent/history'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _recentPayments = List<Map<String, dynamic>>.from(jsonDecode(res.body)['data']['history']);
          _loadingPayments = false;
        });
      } else {
        setState(() => _loadingPayments = false);
      }
    } catch (e) {
      setState(() => _loadingPayments = false);
    }
  }

  Future<void> _fetchNotices() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notices'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          _autoAlerts = List<Map<String, dynamic>>.from(data['auto_alerts']);
          _notices    = List<Map<String, dynamic>>.from(data['notices']);
          _loadingNotices = false;
        });
      } else {
        setState(() => _loadingNotices = false);
      }
    } catch (e) {
      debugPrint('fetchNotices error: $e');
      setState(() => _loadingNotices = false);
    }
  }

  List<Map<String, dynamic>> get _allNotices => [..._autoAlerts, ..._notices];

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final tenant = state.tenant;
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchNotices,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, tenant, state, isDark),
                const SizedBox(height: 20),

                // ── NOTICE BOARD CARD (replaces rent card) ──
                _buildNoticeBoardCard(isDark),

                const SizedBox(height: 20),

                // ── QUICK ACTIONS ──
                _buildQuickActions(context, isDark),

                const SizedBox(height: 20),
                _buildRewardsSection(context, tenant, isDark),
                const SizedBox(height: 20),
                _buildRecentActivity(context, state, isDark),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── BIG NOTICE BOARD CARD ──
  Widget _buildNoticeBoardCard(bool isDark) {
    if (_loadingNotices) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_allNotices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('📋', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Notice Board', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
            SizedBox(height: 16),
            Text('No new notices 🎉', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('All clear for now!', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }

    final notice = _allNotices[_currentNoticeIndex];
    final isAlert = _autoAlerts.contains(notice);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _noticeGradient(notice['type']),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _noticeGradient(notice['type'])[0].withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(_noticeIcon(notice['type']), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text('Notice Board', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Alert', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Notice title
          Text(notice['title'],
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),

          // Notice message
          Text(notice['message'],
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),

          const SizedBox(height: 16),

          // Dot indicators + navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dots
              Row(
                children: List.generate(_allNotices.length, (i) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _currentNoticeIndex ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentNoticeIndex ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              // Prev / Next arrows
              Row(
                children: [
                  GestureDetector(
                    onTap: _currentNoticeIndex > 0
                        ? () => setState(() => _currentNoticeIndex--)
                        : null,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_currentNoticeIndex > 0 ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _currentNoticeIndex < _allNotices.length - 1
                        ? () => setState(() => _currentNoticeIndex++)
                        : null,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_currentNoticeIndex < _allNotices.length - 1 ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _noticeGradient(String? type) {
    switch (type) {
      case 'urgent': return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case 'rent':   return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      case 'maintenance': return [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)];
      default:       return [const Color(0xFF059669), const Color(0xFF10B981)];
    }
  }

  String _noticeIcon(String? type) {
    switch (type) {
      case 'urgent': return '🚨';
      case 'rent':   return '💰';
      case 'maintenance': return '🔧';
      default:       return '📢';
    }
  }

  String _formatMonth(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return 'Rent - ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Rent - $dateStr';
    }
  }

  Widget _buildHeader(BuildContext context, tenant, AppState state, bool isDark) {
    return Row(
      children: [
        AvatarWidget(name: tenant.name, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back! 👋',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppTheme.textMid)),
              Text(tenant.name,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textDark)),
              Text('${tenant.pgName} • ${tenant.room}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppTheme.textMid)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => state.toggleDarkMode(),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white24 : AppTheme.border),
            ),
            child: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.white70 : AppTheme.textMid, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white24 : AppTheme.border),
              ),
              child: Icon(Icons.notifications_outlined,
                  color: isDark ? Colors.white70 : AppTheme.textMid, size: 20),
            ),
            if (_autoAlerts.isNotEmpty)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textDark)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Pay Rent → goes to RentScreen
              QuickActionButton(
                icon: Icons.receipt_long,
                label: 'Pay Rent',
                color: AppTheme.primary,
                onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RentScreen())),
              ),
              // Chat
              QuickActionButton(
                icon: Icons.chat_bubble,
                label: 'Chat',
                color: AppTheme.secondary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatScreen())),
              ),
              // Visitors
              QuickActionButton(
                icon: Icons.person_add,
                label: 'Add Visitor',
                color: AppTheme.success,
                onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VisitorsScreen())),
              ),
              // SOS
              QuickActionButton(
                icon: Icons.sos,
                label: 'SOS',
                color: AppTheme.danger,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context, tenant, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                child: const Text('⭐', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reward Points',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppTheme.textMid)),
                    Row(
                      children: [
                        Text('${tenant.rewardPoints}',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppTheme.textDark)),
                        const SizedBox(width: 8),
                        Text('pts',
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : AppTheme.textMid)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Redeem',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Text('🏅', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('On-Time Payer Badge Earned!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    Text('Paid on time for 3+ months straight',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, AppState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textDark)),
            const Text('See All',
                style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingPayments)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_recentPayments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('No payment history yet', style: TextStyle(color: AppTheme.textMid))),
          )
        else
          ..._recentPayments.take(3).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatMonth(p["month"] ?? ""),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                                color: isDark ? Colors.white : AppTheme.textDark)),
                        Text(p["payment_date"] ?? p["due_date"] ?? "",
                            style: TextStyle(fontSize: 12,
                                color: isDark ? Colors.white54 : AppTheme.textMid)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs.${p["amount"]}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                              color: isDark ? Colors.white : AppTheme.textDark)),
                      StatusBadge(status: p["status"] ?? ""),
                    ],
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }
}