// lib/screens/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatbot_screen.dart';
import 'MultimediaScreen.dart';   // ✅ FIXED: was MultimediaScreen.dart

class RecipeDetailScreen extends StatefulWidget {
  final String               docId;
  final Map<String, dynamic> data;

  const RecipeDetailScreen({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tab;
  double _rating = 0;

  // ✅ Use a local copy so Firestore updates reflect immediately in UI
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _tab    = TabController(length: 2, vsync: this);
    _rating = (widget.data['rating'] ?? 0).toDouble();
    _data   = Map<String, dynamic>.from(widget.data);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _rate(double v) async {
    setState(() => _rating = v);
    await FirebaseFirestore.instance
        .collection('recipes').doc(widget.docId)
        .update({'rating': v});
  }

  Future<void> _toggle(String field) async {
    final val = !(_data[field] ?? false);
    setState(() => _data[field] = val);
    await FirebaseFirestore.instance
        .collection('recipes').doc(widget.docId)
        .update({field: val});
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => ChatbotScreen(recipeContext: _data))),
        backgroundColor: theme.primaryColor,
        icon:  const Icon(Icons.smart_toy_outlined, color: Colors.white),
        label: const Text('Ask Chef AI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: Text(_data['name'] ?? '', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _data['isFavorite'] == true
                  ? Icons.favorite : Icons.favorite_border,
              color: Colors.red.shade300,
            ),
            onPressed: () => _toggle('isFavorite'),
          ),
          IconButton(
            icon: Icon(
              _data['isSaved'] == true
                  ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.yellow.shade300,
            ),
            onPressed: () => _toggle('isSaved'),
          ),
          // ✅ Multimedia button — opens video/audio screen
          IconButton(
            tooltip: 'Video & Audio',
            icon: const Icon(Icons.perm_media_outlined, color: Colors.white),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => MultimediaScreen(
                        docId:      widget.docId,
                        recipeData: _data,
                      )));
              // ✅ Refresh data when coming back so badges update
              if (!mounted) return;
              final doc = await FirebaseFirestore.instance
                  .collection('recipes').doc(widget.docId).get();
              if (mounted && doc.data() != null) {
                setState(() => _data = Map<String, dynamic>.from(doc.data()!));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller:           _tab,
          indicatorColor:       Colors.white,
          labelColor:           Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Recipe'),
            Tab(icon: Icon(Icons.info_outline),        text: 'Details'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tab,
        children: [
          _RecipeTab(
            data:   _data,
            rating: _rating,
            onRate: _rate,
            isDark: isDark,
            theme:  theme,
          ),
          _DetailsTab(data: _data, isDark: isDark, theme: theme),
        ],
      ),
    );
  }
}

class _RecipeTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final double               rating;
  final ValueChanged<double> onRate;
  final bool                 isDark;
  final ThemeData            theme;

  const _RecipeTab({
    required this.data, required this.rating,
    required this.onRate, required this.isDark, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        Stack(children: [
          data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
              ? Image.network(
            data['imageUrl'],
            height: 260, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(260),
          )
              : _placeholder(260),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [
                    isDark ? Colors.grey.shade900 : Colors.white,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ]),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['name'] ?? '',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.timer_outlined,
                    color: Color(0xFF22C55E), size: 18),
                const SizedBox(width: 6),
                Text(data['time'] ?? '',
                    style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color)),
              ]),
              const SizedBox(height: 16),

              // ✅ Star rating — tappable, saves to Firestore
              Row(children: [
                Text('Your rating: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    )),
                ...List.generate(5, (i) => GestureDetector(
                  onTap: () => onRate(i + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size:  30,
                    ),
                  ),
                )),
                const SizedBox(width: 8),
                Text(
                  rating > 0 ? rating.toStringAsFixed(0) : 'Tap to rate',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              _InfoCard(title: '🥗 Ingredients',
                  content: data['ingredients'] ?? '', isDark: isDark, theme: theme),
              _InfoCard(title: '👨‍🍳 Steps',
                  content: data['steps'] ?? '', isDark: isDark, theme: theme),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget _placeholder(double h) => Container(
    height: h, color: Colors.grey.shade200,
    child: const Center(
        child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey)),
  );
}

class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool                 isDark;
  final ThemeData            theme;

  const _DetailsTab({
    required this.data, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(children: [
        _InfoCard(title: '📖 Description',
            content: data['description'] ?? '', isDark: isDark, theme: theme),
        _Row(icon: Icons.timer_outlined, label: 'Cooking Time',
            value: data['time'] ?? 'N/A', theme: theme),
        _Row(icon: Icons.star_outline, label: 'Rating',
            value: '${(data['rating'] ?? 0).toStringAsFixed(1)} / 5',
            theme: theme),
        _Row(icon: Icons.favorite_border, label: 'Favourited',
            value: (data['isFavorite'] ?? false) ? 'Yes ❤️' : 'No',
            theme: theme),
        _Row(icon: Icons.bookmark_border, label: 'Saved',
            value: (data['isSaved'] ?? false) ? 'Yes 🔖' : 'No',
            theme: theme),
        if (data['videoUrl'] != null && (data['videoUrl'] as String).isNotEmpty)
          _Row(icon: Icons.videocam_outlined, label: 'Video',
              value: 'Available ✓ — tap 🎬 above',
              theme: theme),
        if (data['audioUrl'] != null && (data['audioUrl'] as String).isNotEmpty)
          _Row(icon: Icons.headphones, label: 'Audio',
              value: 'Available ✓ — tap 🎬 above',
              theme: theme),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, content;
  final bool isDark;
  final ThemeData theme;
  const _InfoCard({
    required this.title, required this.content,
    required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:  const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color)),
        const SizedBox(height: 10),
        Text(content,
            style: TextStyle(fontSize: 15, height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8))),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final ThemeData theme;
  const _Row({required this.icon, required this.label,
    required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color))),
        Flexible(child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(color: theme.textTheme.bodySmall?.color,
                fontSize: 13))),
      ]),
    );
  }
}