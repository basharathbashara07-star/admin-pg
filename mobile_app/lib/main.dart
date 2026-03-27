import 'package:flutter/material.dart';
import 'screens/common/splash_screen.dart';
import 'screens/admin/dashboard_screen.dart';

// ── Global theme notifier ──
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              primary:   Color(0xFF2196F3),
              secondary: Color(0xFF4CAF50),
              surface:   Color(0xFFFFFFFF),
              error:     Color(0xFFF44336),
            ),
            cardColor: Colors.white,
            dividerColor: const Color(0xFFEEEEEE),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F1432),
            colorScheme: const ColorScheme.dark(
              primary:   Color(0xFF2196F3),
              secondary: Color(0xFF4CAF50),
              surface:   Color(0xFF161E44),
              error:     Color(0xFFF44336),
            ),
            cardColor: const Color(0xFF161E44),
            dividerColor: const Color(0xFF1E2855),
            useMaterial3: true,
          ),

          home: const SplashScreen(), // 👈 keep this for now
        );
      },
    );
  }
}