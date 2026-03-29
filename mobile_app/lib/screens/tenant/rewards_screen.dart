
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';


class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  

  String token = '';
  Map<String, dynamic> rewardData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('tenant_token') ?? '';
    await _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/rewards'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => rewardData = data['data']);
      }
    } catch (e) {
      debugPrint('fetchRewards error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _redeemPoints(String reason, int pts) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/rewards/redeem'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'points': pts, 'reason': reason}),
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        await _fetchRewards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: AppTheme.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('redeemPoints error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = rewardData['total_points'] ?? 0;
    final earned      = rewardData['earned']       ?? 0;
    final redeemed    = rewardData['redeemed']     ?? 0;
    final badges      = rewardData['badges']       as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Rewards & Badges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRewards,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Points header
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            '$totalPoints',
                            style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900),
                          ),
                          const Text('Total Points', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPointStat('Earned', '$earned', Colors.white),
                              _buildPointStat('Redeemed', '$redeemed', Colors.white),
                              _buildPointStat('Balance', '$totalPoints', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // How to earn
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: '💡 How to Earn Points'),
                          const SizedBox(height: 12),
                          _buildEarnItem('Pay rent on time', '+10 pts', AppTheme.success),
                          _buildEarnItem('Pay 5 days early', '+20 pts', AppTheme.primary),
                          _buildEarnItem('Register visitor', '+5 pts', AppTheme.secondary),
                          _buildEarnItem('Pay 3 months in a row', '+15 pts', AppTheme.warning),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Badges
                    const SectionHeader(title: 'Badges & Achievements'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        final isEarned = badge['earned'] == true;
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          color: isEarned ? const Color(0xFFFFFBEB) : Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Text(badge['icon'] ?? '🏅', style: const TextStyle(fontSize: 32)),
                                  if (!isEarned)
                                    const Icon(Icons.lock, size: 14, color: AppTheme.textLight),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                badge['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isEarned ? AppTheme.textDark : AppTheme.textLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                badge['description'] ?? '',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMid),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Redeem
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: '🎁 Redeem Points'),
                          const SizedBox(height: 12),
                          _buildRedeemItem(context, 'Rent Discount ₹50', 50),
                          _buildRedeemItem(context, 'Free Laundry Pass', 30),
                          _buildRedeemItem(context, 'Guest Room 1 Day Free', 100),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPointStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildEarnItem(String label, String points, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDark))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(points, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemItem(BuildContext context, String title, int pts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textDark))),
          GestureDetector(
            onTap: () => _redeemPoints(title, pts),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$pts pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}