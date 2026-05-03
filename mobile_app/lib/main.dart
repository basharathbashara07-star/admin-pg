import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'screens/common/splash_screen.dart';
import 'models/tenant_app_state.dart';
import 'services/api_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<bool> sosActiveNotifier = ValueNotifier(false);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _sosTimer;

  @override
  void initState() {
    super.initState();
    _startSOSChecker();
  }

  void _startSOSChecker() {
    _sosTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      try {
        final res = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/admin/emergency/alerts'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final alerts = List<Map<String, dynamic>>.from(data['alerts']);
          final hasActive = alerts.any((a) => a['status'] == 'active');

          if (hasActive && !sosActiveNotifier.value) {
            sosActiveNotifier.value = true;
            // Vibrate long
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(
                pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000],
                repeat: 0,
              );
            }
          } else if (!hasActive) {
            sosActiveNotifier.value = false;
            Vibration.cancel();
          }
        }
      } catch (e) {
        // ignore
      }
    });
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F6FA),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              secondary: Color(0xFF4CAF50),
              surface: Color(0xFFFFFFFF),
              error: Color(0xFFF44336),
            ),
            cardColor: Colors.white,
            dividerColor: const Color(0xFFEEEEEE),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F1432),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2196F3),
              secondary: Color(0xFF4CAF50),
              surface: Color(0xFF161E44),
              error: Color(0xFFF44336),
            ),
            cardColor: const Color(0xFF161E44),
            dividerColor: const Color(0xFF1E2855),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}