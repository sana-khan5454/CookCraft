// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RecipeApp());
}

// Global dark mode notifier — used by SettingsScreen
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Recipe App',

          // ── Light theme ────────────────────────────────────
          theme: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF22C55E),
            scaffoldBackgroundColor: const Color(0xFFF8F4F0),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF22C55E),
            ),
            textTheme: const TextTheme(
              bodyMedium:    TextStyle(color: Colors.black87),
              bodySmall:     TextStyle(color: Colors.black54),
              bodyLarge:     TextStyle(color: Colors.black87),
              headlineLarge: TextStyle(color: Colors.black87),
              titleLarge:    TextStyle(color: Colors.black87),
              titleMedium:   TextStyle(color: Colors.black87),
            ),
          ),

          // ── Dark theme ─────────────────────────────────────
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF22C55E),
            scaffoldBackgroundColor: Colors.grey[900],
            cardColor: Colors.grey[850],
            appBarTheme: const AppBarTheme(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF22C55E),
            ),
            textTheme: const TextTheme(
              bodyMedium:    TextStyle(color: Colors.white),
              bodySmall:     TextStyle(color: Colors.white70),
              bodyLarge:     TextStyle(color: Colors.white),
              headlineLarge: TextStyle(color: Colors.white),
              titleLarge:    TextStyle(color: Colors.white),
              titleMedium:   TextStyle(color: Colors.white),
            ),
          ),

          themeMode:    currentMode,
          initialRoute: '/',

          routes: {
            '/':               (_) => const SplashScreen(),
            '/roleSelect':     (_) => const RoleSelectionScreen(),       // NEW
            '/login':          (_) => const LoginScreen(role: 'user'),   // fallback
            '/signup':         (_) => const SignupScreen(),
            '/home':           (_) => const HomeScreen(),
            '/userDashboard':  (_) => const UserDashboardScreen(),
            '/adminDashboard': (_) => const AdminDashboardScreen(),
            '/profile':        (_) => const UserProfileScreen(),
            '/settings':       (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}