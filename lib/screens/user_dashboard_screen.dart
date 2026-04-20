// lib/screens/user_dashboard_screen.dart
// ✅ Shows recipe image + video badge prominently
// ✅ Tapping card opens RecipeDetailScreen
// ✅ Profile pic shown from Firestore

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail_screen.dart';
import 'user_profile_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String  _userName        = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      if (!mounted) return;
      setState(() {
        _userName        = doc.data()?['name'] ?? 'User';
        _profileImageUrl = doc.data()?['profileImageUrl'];
      });
    } catch (_) {
      if (mounted) setState(() => _userName = 'User');
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ── Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:        theme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(children: [
                    // Profile pic — tappable
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const UserProfileScreen()));
                        // Refresh profile pic after returning
                        _loadUser();
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        backgroundImage: (_profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty)
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: (_profileImageUrl == null ||
                            _profileImageUrl!.isEmpty)
                            ? const Icon(Icons.person,
                            color: Colors.white, size: 26)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          _userName.isEmpty ? '...' : _userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.orange, size: 14),
                          SizedBox(width: 4),
                          Text('Explore',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Section title ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Latest Recipes',
                    style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                      color:      theme.textTheme.bodyLarge?.color,
                    )),
              ),
            ),

            // ── Recipe feed ─────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🍲',
                              style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 12),
                          Text('No recipes yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.5),
                              )),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) {
                        final doc  = docs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return _RecipeCard(
                          data:   data,
                          docId:  doc.id,
                          isDark: isDark,
                          theme:  theme,
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recipe Card ────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String    docId;
  final bool      isDark;
  final ThemeData theme;

  const _RecipeCard({
    required this.data, required this.docId,
    required this.isDark, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final audioUrl = data['audioUrl'] as String?;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasAudio = audioUrl != null && audioUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                  data: data, docId: docId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color:        theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Image with badges ───────────────────────────
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                height: 200, width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200, color: Colors.grey.shade100,
                    child: const Center(
                        child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
            ),

            // Media badges top-right
            if (hasVideo || hasAudio)
              Positioned(
                top: 10, right: 10,
                child: Row(children: [
                  if (hasVideo)
                    _Badge(
                      icon:  Icons.videocam_rounded,
                      label: 'Video',
                      color: Colors.blue.shade700,
                    ),
                  if (hasVideo && hasAudio) const SizedBox(width: 6),
                  if (hasAudio)
                    _Badge(
                      icon:  Icons.headphones,
                      label: 'Audio',
                      color: Colors.purple.shade700,
                    ),
                ]),
              ),
          ]),

          // ── Text info ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text(data['time'] ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color)),
                  const SizedBox(width: 14),
                  const Icon(Icons.star, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text((data['rating'] ?? 0).toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color)),
                ]),
                const SizedBox(height: 6),
                Text(
                  data['description'] ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13, height: 1.4,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 200, color: Colors.grey.shade200,
    child: const Center(child: Icon(Icons.restaurant_menu,
        size: 60, color: Colors.grey)),
  );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}