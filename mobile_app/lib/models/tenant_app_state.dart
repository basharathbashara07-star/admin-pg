import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tenant_models.dart';

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

  // Load tenant info from saved JWT token
  Future<void> loadTenantFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      // JWT is 3 parts split by '.', payload is part index 1
      final parts = token.split('.');
      if (parts.length != 3) return;

      // Base64 decode the payload
      String payload = parts[1];
      // Pad base64 string if needed
      while (payload.length % 4 != 0) payload += '=';
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));

      _tenant = Tenant(
        name:         decoded['name']     ?? '',
        room:         decoded['room_no']  ?? '',
        pgName:       decoded['pg_name']  ?? '',
        avatar:       '',
        rewardPoints: 0,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Token decode error: $e');
    }
  }

  // Call this on logout
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
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
    notifyListeners();
  }

  void setTab(int index) {
    currentTab = index;
    notifyListeners();
  }
}