import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tenant_models.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:mobile_app/main.dart';

class AppState extends ChangeNotifier {
  bool isDarkMode = false;
  int currentTab = 0;

  Tenant _tenant = Tenant(
    name: '',
    room: '',
    pgName: '',
    avatar: '',
    rewardPoints: 0,
  );

  Tenant get tenant => _tenant;

  Future<void> loadTenantFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tenant_token');
    print('TENANT TOKEN: $token');
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        _tenant = Tenant(
          name: data['name'] ?? '',
          room: data['room_no'] ?? '',
          pgName: data['pg_name'] ?? '',
          avatar: '',
          rewardPoints: 0,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadTenant error: $e');
    }
  }

  // Call this on logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tenant_token');
    _tenant = Tenant(name: '', room: '', pgName: '', avatar: '', rewardPoints: 0);
    notifyListeners();
  }

  final List<Payment> payments = [];
  final List<MaintenanceTicket> tickets = [];
  final List<Expense> expenses = [];
  final List<Notice> notices = [];
  final List<ChatMessage> wardenChat = [];
  final List<ChatMessage> roommateChat = [];
  final List<TenantBadge> badges = [];

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  void setTab(int index) {
    currentTab = index;
    notifyListeners();
  }
}