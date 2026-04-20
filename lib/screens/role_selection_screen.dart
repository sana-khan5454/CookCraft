// lib/screens/role_selection_screen.dart
// ✅ NEW — Role selection screen shown before login
// Tapping a card navigates to LoginScreen with the role pre-selected.

import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double>    _fadeIn;
  late Animation<Offset>    _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn  = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin(String role) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LoginScreen(role: role),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background gradient
    final bg = isDark
        ? const [Color(0xFF1A2E1A), Color(0xFF0F1F0F)]
        : const [Color(0xFFF0F7EE), Color(0xFFFFFBF5)];

    return Scaffold(
      body: Container(
        width:  size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bg,
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [

                    SizedBox(height: size.height * 0.07),

                    // ── Logo / branding ──────────────────────────
                    Container(
                      width:  80, height: 80,
                      decoration: BoxDecoration(
                        color:        const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:      const Color(0xFF22C55E).withOpacity(0.35),
                            blurRadius: 24,
                            offset:     const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🍳', style: TextStyle(fontSize: 38)),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Recipe App',
                      style: TextStyle(
                        fontSize:   32,
                        fontWeight: FontWeight.w800,
                        color:      isDark ? Colors.white : const Color(0xFF1A2E1A),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Who are you cooking as today?',
                      style: TextStyle(
                        fontSize: 16,
                        color:    isDark
                            ? Colors.white.withOpacity(0.55)
                            : const Color(0xFF1A2E1A).withOpacity(0.5),
                      ),
                    ),

                    SizedBox(height: size.height * 0.07),

                    // ── User card ────────────────────────────────
                    _RoleCard(
                      emoji:       '👩‍🍳',
                      title:       'I\'m a Food Lover',
                      subtitle:    'Browse recipes, save favourites\nand get AI cooking help',
                      accentColor: const Color(0xFF22C55E),
                      isDark:      isDark,
                      onTap:       () => _goToLogin('user'),
                    ),

                    const SizedBox(height: 20),

                    // ── Admin card ───────────────────────────────
                    _RoleCard(
                      emoji:       '👨‍💼',
                      title:       'I\'m an Admin',
                      subtitle:    'Manage recipes, upload content\nand maintain the app',
                      accentColor: const Color(0xFFE07B39),
                      isDark:      isDark,
                      onTap:       () => _goToLogin('admin'),
                    ),

                    const Spacer(),

                    // ── Bottom tagline ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Cook something amazing today 🌿',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF1A2E1A).withOpacity(0.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role Card ──────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color  accentColor;
  final bool   isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double>    _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0, upperBound: 0.03,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark
        ? const Color(0xFF1E3320)
        : Colors.white;

    return GestureDetector(
      onTapDown:   (_) => _press.forward(),
      onTapUp:     (_) { _press.reverse(); widget.onTap(); },
      onTapCancel: ()  => _press.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:        cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:      widget.isDark
                    ? Colors.black.withOpacity(0.3)
                    : widget.accentColor.withOpacity(0.12),
                blurRadius: 20,
                offset:     const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [

              // Emoji bubble
              Container(
                width:  68, height: 68,
                decoration: BoxDecoration(
                  color:        widget.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(widget.emoji,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                        color:      widget.isDark
                            ? Colors.white
                            : const Color(0xFF1A2E1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height:   1.45,
                        color:    widget.isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF1A2E1A).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Arrow
              Container(
                width:  36, height: 36,
                decoration: BoxDecoration(
                  color:        widget.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}