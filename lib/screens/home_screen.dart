// lib/screens/home_screen.dart
// ✅ Global chatbot FAB on every tab via Scaffold-level placement
// ✅ IndexedStack preserves state across tab switches

import 'package:flutter/material.dart';
import 'user_dashboard_screen.dart';
import 'search_screen.dart';
import 'recommendation_screen.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const UserDashboardScreen(),
      const SearchScreen(),
      const RecommendationScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ChatbotScreen(), // no recipeContext = general mode
        )),
        backgroundColor: theme.primaryColor,
        tooltip: 'Chef AI Assistant',
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:        _index,
        selectedItemColor:   theme.primaryColor,
        unselectedItemColor: Colors.grey,
        type:                BottomNavigationBarType.fixed,
        backgroundColor:     theme.cardColor,
        elevation:           12,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search),
              label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department_outlined),
              activeIcon: Icon(Icons.local_fire_department),
              label: 'Trending'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}