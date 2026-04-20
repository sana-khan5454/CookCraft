// lib/screens/splash_screen.dart
// ✅ UPDATED — navigates to RoleSelectionScreen instead of LoginScreen directly

import 'package:flutter/material.dart';
import 'role_selection_screen.dart';   // ← changed from login_screen.dart

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Hero image
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: theme.cardColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/chef.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.restaurant_menu,
                          size: 100, color: theme.primaryColor),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),

                    Text(
                      "It's\nCooking Time!",
                      style: TextStyle(
                        fontSize:      38,
                        fontWeight:    FontWeight.bold,
                        color:         theme.textTheme.bodyLarge?.color,
                        height:        1.2,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Discover delicious recipes, save your favourites "
                          "and cook like a chef every day.",
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity, height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 6,
                          shadowColor:
                          theme.primaryColor.withOpacity(0.4),
                        ),
                        onPressed: () {
                          // ✅ Goes to role selection, not login directly
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, anim, __) =>
                              const RoleSelectionScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                              const Duration(milliseconds: 400),
                            ),
                          );
                        },
                        child: const Text(
                          "Let's Get Started",
                          style: TextStyle(
                              fontSize:   18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}