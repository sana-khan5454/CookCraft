import 'package:flutter/material.dart';
import 'post_recipe_screen.dart';
import 'view_recipes_screen.dart';
import 'role_selection_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: theme.primaryColor,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_menu,
                            size: 36, color: Colors.white),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello Admin 👨‍🍳",
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color ??
                                    Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Manage and publish delicious recipes.",
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7) ??
                                    Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const RoleSelectionScreen(),
                            ),
                                (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ POST RECIPE
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PostRecipeScreen(),
                    ),
                  ),
                  child: _ActionCard(
                    icon: Icons.add_a_photo_rounded,
                    iconColor: const Color(0xFF16A34A),
                    title: "Post Recipe",
                    subtitle:
                    "Add a new recipe with image, ingredients and steps",
                    theme: theme,
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ VIEW RECIPES (FIXED)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewRecipesScreen(),
                    ),
                  ),
                  child: _ActionCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: Colors.deepOrange,
                    title: "View Recipes",
                    subtitle:
                    "See and edit all recipes posted in your app",
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ThemeData theme;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    )),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.6),
                    )),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: theme.iconTheme.color),
        ],
      ),
    );
  }
}