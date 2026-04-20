// lib/screens/settings_screen.dart
// ✅ Fixed: LoginScreen() → RoleSelectionScreen() on logout
//           (LoginScreen now requires role param — go to role selection instead)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // for themeNotifier
import 'role_selection_screen.dart'; // ← FIXED import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // ✅ FIXED: go to role selection, not LoginScreen directly
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            (route) => false,
      );
    }
  }

  void _toggleDarkMode(bool value) {
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Logout ────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:   const Text("Logout",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap:   _logout,
            ),
          ),

          const SizedBox(height: 15),

          // ── Dark mode ─────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 3,
            child: SwitchListTile(
              title:     const Text("Dark Mode",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.dark_mode),
              value:     themeNotifier.value == ThemeMode.dark,
              onChanged: _toggleDarkMode,
            ),
          ),

          const SizedBox(height: 15),

          // ── Notifications ─────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 3,
            child: SwitchListTile(
              title:     const Text("Notifications",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.notifications),
              value:     _notifications,
              onChanged: (val) => setState(() => _notifications = val),
            ),
          ),

          const SizedBox(height: 15),

          // ── Privacy ───────────────────────────────────────
          ExpansionTile(
            leading: const Icon(Icons.lock),
            title:   const Text("Privacy",
                style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(
                title:  const Text("Change Password"),
                onTap:  _resetPassword,
              ),
              const ListTile(title: Text("Terms & Conditions")),
            ],
          ),

          const SizedBox(height: 15),

          // ── About ─────────────────────────────────────────
          const ExpansionTile(
            leading: Icon(Icons.info),
            title:   Text("About",
                style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(title: Text("App Version: 1.0.0")),
              ListTile(title: Text("Developer: Shivani")),
            ],
          ),
        ],
      ),
    );
  }
}