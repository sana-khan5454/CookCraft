// lib/screens/user_profile_screen.dart
// ✅ Web-safe: uses Uint8List on web, File on mobile
// ✅ Upload progress shown
// ✅ Profile pic stored in Firebase, shown in dashboard header

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Profile image — web uses bytes, mobile uses File
  Uint8List? _webImageBytes;
  File?      _mobileImageFile;
  String?    _profileImageUrl;  // existing URL from Firestore

  bool _isLoading  = true;   // loading user data
  bool _isSaving   = false;
  double _uploadProgress = 0;

  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Load user data ─────────────────────────────────────

  Future<void> _loadUser() async {
    if (_user == null) { setState(() => _isLoading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(_user!.uid).get();
      if (!mounted) return;
      final data = doc.data();
      _nameCtrl.text  = data?['name']  ?? '';
      _emailCtrl.text = data?['email'] ?? '';
      setState(() {
        _profileImageUrl = data?['profileImageUrl'];
        _isLoading       = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Pick profile image ─────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source:       ImageSource.gallery,
      imageQuality: 80,
      maxWidth:     600,
    );
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() { _webImageBytes = bytes; _mobileImageFile = null; });
    } else {
      setState(() { _mobileImageFile = File(picked.path); _webImageBytes = null; });
    }
  }

  // ── Upload profile image ───────────────────────────────

  Future<String?> _uploadImage() async {
    // No new image picked — return existing URL
    if (_webImageBytes == null && _mobileImageFile == null) {
      return _profileImageUrl;
    }
    if (_user == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref().child('profile_pics/${_user!.uid}.jpg');

      late UploadTask task;
      if (kIsWeb) {
        task = ref.putData(_webImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putFile(_mobileImageFile!);
      }

      task.snapshotEvents.listen((s) {
        if (!mounted) return;
        setState(() =>
        _uploadProgress = s.bytesTransferred / s.totalBytes);
      });

      final snap = await task;
      if (snap.state != TaskState.success) {
        throw Exception('Upload failed');
      }
      return await ref.getDownloadURL();
    } catch (e) {
      _snack('Image upload failed: $e');
      return _profileImageUrl; // keep old URL on failure
    }
  }

  // ── Save changes ───────────────────────────────────────

  Future<void> _save() async {
    if (_user == null || _isLoading) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack('Name cannot be empty'); return; }

    setState(() { _isSaving = true; _uploadProgress = 0; });

    try {
      final imageUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('users').doc(_user!.uid)
          .update({
        'name':            name,
        'email':           _emailCtrl.text.trim(),
        'profileImageUrl': imageUrl,
      });

      await _user!.updateDisplayName(name);

      if (!mounted) return;
      setState(() {
        _profileImageUrl = imageUrl;
        _webImageBytes   = null;
        _mobileImageFile = null;
      });
      _snack('Profile updated ✓');
    } catch (e) {
      if (mounted) _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() { _isSaving = false; _uploadProgress = 0; });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color;

    // Determine which image to show
    ImageProvider? imageProvider;
    if (_webImageBytes != null) {
      imageProvider = MemoryImage(_webImageBytes!);
    } else if (_mobileImageFile != null) {
      imageProvider = FileImage(_mobileImageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [

          // ── Profile picture ───────────────────────
          Stack(children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person,
                  size: 60, color: theme.primaryColor)
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 10),
          Text('${_greeting()},',
              style: TextStyle(
                  fontSize: 15, color: textColor?.withOpacity(0.6))),

          // New image selected indicator
          if (_webImageBytes != null || _mobileImageFile != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color:        theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('New photo selected — tap Save to apply',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.primaryColor,
                  )),
            ),
          ],

          const SizedBox(height: 24),

          // Upload progress during save
          if (_isSaving && _uploadProgress > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           _uploadProgress,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.primaryColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading photo... ${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 13, color: theme.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // ── Name field ────────────────────────────
          TextField(
            controller: _nameCtrl,
            enabled:    !_isSaving,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText:  'Full Name',
              labelStyle: TextStyle(color: textColor?.withOpacity(0.7)),
              prefixIcon: Icon(Icons.person_outline,
                  color: theme.primaryColor),
              filled:    true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:   BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Email field ───────────────────────────
          TextField(
            controller: _emailCtrl,
            enabled:    !_isSaving,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText:  'Email',
              labelStyle: TextStyle(color: textColor?.withOpacity(0.7)),
              prefixIcon: Icon(Icons.email_outlined,
                  color: theme.primaryColor),
              filled:    true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:   BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Save button ───────────────────────────
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: (_isSaving || _isLoading) ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Settings shortcut ─────────────────────
          Card(
            color: isDark ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.settings_outlined,
                  color: theme.primaryColor),
              title: Text('Settings',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 15),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ]),
      ),
    );
  }
}