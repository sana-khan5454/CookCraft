// lib/screens/recommendation_screen.dart
// ✅ Shows top-rated recipes with images
// ✅ Tapping navigates to RecipeDetailScreen

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail_screen.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('🔥', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trending Recipes',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Top rated by our community',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ]),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Hot Right Now 🌶️',
                    style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                      color:      theme.textTheme.bodyLarge?.color,
                    )),
              ),
            ),

            // ── Recipe list sorted by rating ───────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('rating', descending: true)
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
                          const Text('🍽️', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          Text('No trending recipes yet',
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
                        final doc    = docs[i];
                        final data   = doc.data() as Map<String, dynamic>;
                        final rating = (data['rating'] ?? 0).toDouble();
                        return _TrendingCard(
                          data:    data,
                          docId:   doc.id,
                          rank:    i + 1,
                          rating:  rating,
                          isDark:  isDark,
                          theme:   theme,
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

class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String    docId;
  final int       rank;
  final double    rating;
  final bool      isDark;
  final ThemeData theme;

  const _TrendingCard({
    required this.data, required this.docId, required this.rank,
    required this.rating, required this.isDark, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Top 3 get a flame gradient, rest are plain
    final isTop3 = rank <= 3;
    final rankColors = [
      [const Color(0xFFFFD700), const Color(0xFFFFA500)], // gold
      [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)], // silver
      [const Color(0xFFCD7F32), const Color(0xFFA0522D)], // bronze
    ];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(data: data, docId: docId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:        theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [

          // ── Thumbnail ────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20)),
            child: Image.network(
              data['imageUrl'] ?? '',
              width:  100,
              height: 100,
              fit:    BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100,
                color: Colors.grey.shade200,
                child: const Icon(Icons.restaurant,
                    color: Colors.grey, size: 36),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '',
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.bold,
                        color:      theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: Color(0xFF22C55E)),
                    const SizedBox(width: 4),
                    Text(data['time'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        )),
                  ]),
                  const SizedBox(height: 6),
                  // Star rating display
                  Row(children: List.generate(5, (i) => Icon(
                    i < rating.round() ? Icons.star : Icons.star_border,
                    size:  14,
                    color: Colors.orange,
                  ))),
                ],
              ),
            ),
          ),

          // ── Rank badge ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width:  36, height: 36,
              decoration: BoxDecoration(
                gradient: isTop3
                    ? LinearGradient(
                  colors: rankColors[rank - 1].cast<Color>(),
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                )
                    : null,
                color: !isTop3
                    ? (isDark ? Colors.grey[700] : Colors.grey.shade200)
                    : null,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('#$rank',
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    )),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}