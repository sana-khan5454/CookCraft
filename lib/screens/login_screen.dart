// lib/screens/login_screen.dart
// ✅ Admin check: hardcoded email + password (no Firestore needed)
// ✅ Accepts role from RoleSelectionScreen
// ✅ Password visibility toggle
// ✅ After login: admin → AdminDashboardScreen, user → HomeScreen

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

// ── Admin credentials — change these to whatever you want ─────────────────
const String _adminEmail    = 'admin@gmail.com';
const String _adminPassword = 'admin123';
// ─────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final String role; // 'user' or 'admin'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<double>    _fadeIn;
  late Animation<Offset>    _slideUp;

  Color  get _accent => widget.role == 'admin'
      ? const Color(0xFFE07B39)
      : const Color(0xFF22C55E);
  String get _roleLabel => widget.role == 'admin' ? 'Admin'      : 'Food Lover';
  String get _roleEmoji => widget.role == 'admin' ? '👨‍💼' : '👩‍🍳';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fadeIn  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.14), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter your email and password');
      return;
    }

    // ── Admin path ─────────────────────────────────────────
    if (widget.role == 'admin') {
      if (email != _adminEmail || password != _adminPassword) {
        _snack('Invalid admin credentials');
        return;
      }
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: password);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        _snack(_authError(e.code));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // ── User path ──────────────────────────────────────────
    // Block regular users from using admin credentials
    if (email == _adminEmail) {
      _snack('Use the Admin login for this account');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
      _snack('Welcome back! 👋');
    } on FirebaseAuthException catch (e) {
      if (mounted) _snack(_authError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':return 'Incorrect password';
      case 'invalid-email':     return 'Invalid email address';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default:                  return 'Login failed. Please try again.';
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size   = MediaQuery.of(context).size;

    final bg = isDark
        ? const [Color(0xFF1A2E1A), Color(0xFF0F1F0F)]
        : const [Color(0xFFF0F7EE), Color(0xFFFFFBF5)];

    return Scaffold(
      body: Container(
        width: size.width, height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: bg,
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 20),

                    // ── Back button ──────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset:     const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size:  18,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF1A2E1A)),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Role badge ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:        _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: _accent.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_roleEmoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text('$_roleLabel Login',
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                                color:      _accent,
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Headline ─────────────────────────────────
                    Text(
                      'Welcome\nBack! 👋',
                      style: TextStyle(
                        fontSize:      38,
                        fontWeight:    FontWeight.w800,
                        height:        1.15,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF1A2E1A),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      widget.role == 'admin'
                          ? 'Sign in to manage your recipe collection'
                          : 'Sign in to continue cooking your favourites',
                      style: TextStyle(
                        fontSize: 15,
                        height:   1.5,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF1A2E1A).withOpacity(0.5),
                      ),
                    ),

                    // ── Admin hint box ────────────────────────────
                    if (widget.role == 'admin') ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFE07B39).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE07B39).withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Color(0xFFE07B39)),
                              SizedBox(width: 6),
                              Text('Admin Credentials',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize:   13,
                                      color:      Color(0xFFE07B39))),
                            ]),
                            const SizedBox(height: 8),
                            _credRow('Email',    _adminEmail),
                            const SizedBox(height: 4),
                            _credRow('Password', _adminPassword),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // ── Email field ──────────────────────────────
                    _InputField(
                      controller:   _emailCtrl,
                      hint:         'Email address',
                      icon:         Icons.email_outlined,
                      accent:       _accent,
                      isDark:       isDark,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // ── Password field ───────────────────────────
                    _InputField(
                      controller: _passwordCtrl,
                      hint:       'Password',
                      icon:       Icons.lock_outline_rounded,
                      accent:     _accent,
                      isDark:     isDark,
                      obscure:    _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size:  20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Forgot password (user only) ───────────────
                    if (widget.role == 'user')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const ForgotPasswordScreen())),
                          style: TextButton.styleFrom(
                            padding:         EdgeInsets.zero,
                            minimumSize:     Size.zero,
                            tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Forgot Password?',
                              style: TextStyle(
                                color:      _accent,
                                fontWeight: FontWeight.w600,
                                fontSize:   14,
                              )),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Sign In button ───────────────────────────
                    SizedBox(
                      width: double.infinity, height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation:       0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          shadowColor: _accent.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : const Text('Sign In',
                            style: TextStyle(
                                fontSize:   18,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Divider ──────────────────────────────────
                    Row(children: [
                      Expanded(child: Divider(
                          color: isDark ? Colors.white12 : Colors.black12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white30 : Colors.black38,
                            )),
                      ),
                      Expanded(child: Divider(
                          color: isDark ? Colors.white12 : Colors.black12)),
                    ]),

                    const SizedBox(height: 28),

                    // ── Sign Up (user only) ──────────────────────
                    if (widget.role == 'user')
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Don't have an account?  ",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54 : Colors.black54,
                                )),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignupScreen())),
                              child: Text('Sign Up',
                                  style: TextStyle(
                                    color:      _accent,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ),

                    if (widget.role == 'admin')
                      Center(
                        child: Text(
                          '🔐 Admin access is restricted.\nContact your system administrator if locked out.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height:   1.5,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Small helper row for the admin credentials box
  Widget _credRow(String label, String value) {
    return Row(children: [
      Text('$label: ',
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      const Color(0xFFE07B39).withOpacity(0.8),
          )),
      SelectableText(value,
          style: const TextStyle(
            fontSize:   12,
            fontFamily: 'monospace',
            color:      Color(0xFFE07B39),
          )),
    ]);
  }
}

// ── Reusable input field ───────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final IconData              icon;
  final Color                 accent;
  final bool                  isDark;
  final bool                  obscure;
  final TextInputType         keyboardType;
  final Widget?               suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.isDark,
    this.obscure      = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller:   controller,
        obscureText:  obscure,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF1A2E1A),
        ),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          prefixIcon: Icon(icon,
              size:  20,
              color: isDark ? Colors.white38 : Colors.black38),
          suffixIcon: suffixIcon != null
              ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child:   suffixIcon)
              : null,
          filled:         true,
          fillColor:      Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 18),
          border:        InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:   BorderSide(color: accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}