// lib/screens/post_recipe_screen.dart
// ✅ Image + Video upload during post
// ✅ Web-safe (Uint8List for web, File for mobile)
// ✅ Real upload progress shown
// ✅ All data saved to Firestore correctly

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'cooking_time_picker.dart';

class PostRecipeScreen extends StatefulWidget {
  const PostRecipeScreen({super.key});

  @override
  State<PostRecipeScreen> createState() => _PostRecipeScreenState();
}

class _PostRecipeScreenState extends State<PostRecipeScreen> {
  final _nameCtrl        = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _stepsCtrl       = TextEditingController();

  String     _cookingTime = '';

  // Image
  Uint8List? _webImage;
  File?      _mobileImage;

  // Video
  Uint8List? _webVideo;
  File?      _mobileVideo;
  String?    _videoName;

  bool   _isLoading       = false;
  double _imageProgress   = 0;
  double _videoProgress   = 0;
  String _statusText      = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingredientsCtrl.dispose();
    _descriptionCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ─────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() { _webImage = bytes; _mobileImage = null; });
    } else {
      setState(() { _mobileImage = File(picked.path); _webImage = null; });
    }
  }

  // ── Pick video ─────────────────────────────────────────

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webVideo    = bytes;
        _mobileVideo = null;
        _videoName   = picked.name;
      });
    } else {
      setState(() {
        _mobileVideo = File(picked.path);
        _webVideo    = null;
        _videoName   = picked.name;
      });
    }
  }

  void _removeVideo() {
    setState(() {
      _webVideo    = null;
      _mobileVideo = null;
      _videoName   = null;
    });
  }

  // ── Upload image ───────────────────────────────────────

  Future<String?> _uploadImage(String docId) async {
    final ref = FirebaseStorage.instance
        .ref().child('recipe_images/$docId.jpg');

    late UploadTask task;
    if (kIsWeb) {
      task = ref.putData(_webImage!,
          SettableMetadata(contentType: 'image/jpeg'));
    } else {
      task = ref.putFile(_mobileImage!);
    }

    task.snapshotEvents.listen((s) {
      if (!mounted) return;
      setState(() {
        _imageProgress = s.bytesTransferred / s.totalBytes;
        _statusText    = 'Uploading image... ${(_imageProgress * 100).toInt()}%';
      });
    });

    try {
      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Upload video ───────────────────────────────────────

  Future<String?> _uploadVideo(String docId) async {
    if (_webVideo == null && _mobileVideo == null) return null;

    final ref = FirebaseStorage.instance
        .ref().child('recipe_videos/$docId.mp4');

    late UploadTask task;
    if (kIsWeb) {
      task = ref.putData(_webVideo!,
          SettableMetadata(contentType: 'video/mp4'));
    } else {
      task = ref.putFile(_mobileVideo!);
    }

    task.snapshotEvents.listen((s) {
      if (!mounted) return;
      setState(() {
        _videoProgress = s.bytesTransferred / s.totalBytes;
        _statusText    = 'Uploading video... ${(_videoProgress * 100).toInt()}%';
      });
    });

    try {
      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Post ───────────────────────────────────────────────

  Future<void> _post() async {
    if (_nameCtrl.text.trim().isEmpty)        { _snack('Enter recipe name');  return; }
    if (_cookingTime.isEmpty)                  { _snack('Set cooking time');   return; }
    if (_ingredientsCtrl.text.trim().isEmpty) { _snack('Enter ingredients');  return; }
    if (_descriptionCtrl.text.trim().isEmpty) { _snack('Enter description');  return; }
    if (_stepsCtrl.text.trim().isEmpty)       { _snack('Enter steps');        return; }
    if (_webImage == null && _mobileImage == null) {
      _snack('Select a recipe image'); return;
    }

    setState(() {
      _isLoading     = true;
      _imageProgress = 0;
      _videoProgress = 0;
      _statusText    = 'Preparing...';
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('recipes').doc();

      // Upload image
      setState(() => _statusText = 'Uploading image...');
      final imageUrl = await _uploadImage(docRef.id);
      if (imageUrl == null) {
        _snack('Image upload failed. Check Firebase Storage rules.');
        return;
      }

      // Upload video (optional)
      String? videoUrl;
      if (_webVideo != null || _mobileVideo != null) {
        setState(() => _statusText = 'Uploading video...');
        videoUrl = await _uploadVideo(docRef.id);
      }

      // Save to Firestore
      setState(() => _statusText = 'Saving recipe...');
      await docRef.set({
        'name':        _nameCtrl.text.trim(),
        'time':        _cookingTime,
        'ingredients': _ingredientsCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'steps':       _stepsCtrl.text.trim(),
        'imageUrl':    imageUrl,
        'videoUrl':    videoUrl,
        'audioUrl':    null,
        'rating':      0,
        'isFavorite':  false,
        'isSaved':     false,
        'createdAt':   Timestamp.now(),
      });

      if (!mounted) return;
      _snack('Recipe posted successfully ✓');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() {
        _isLoading     = false;
        _imageProgress = 0;
        _videoProgress = 0;
        _statusText    = '';
      });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
  }

  Widget _field(String hint, TextEditingController ctrl,
      {int maxLines = 1, IconData? icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        maxLines:   maxLines,
        enabled:    !_isLoading,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
          prefixIcon: icon != null
              ? Icon(icon, color: theme.iconTheme.color) : null,
          filled:    true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:   BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final hasImg = _webImage != null || _mobileImage != null;
    final hasVid = _webVideo != null || _mobileVideo != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Post Recipe',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Image picker ────────────────────────────────
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color:        theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: theme.dividerColor),
              ),
              child: !hasImg
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 50, color: theme.primaryColor),
                  const SizedBox(height: 8),
                  Text('Tap to add recipe image *',
                      style: TextStyle(
                          color: theme.textTheme.bodySmall?.color)),
                ],
              )
                  : Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: kIsWeb
                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                      : Image.file(_mobileImage!, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('Change',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // ── Video picker ────────────────────────────────
          GestureDetector(
            onTap: _isLoading ? null : _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(
                  color: hasVid
                      ? theme.primaryColor.withOpacity(0.5)
                      : theme.dividerColor,
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        hasVid
                        ? theme.primaryColor.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasVid ? Icons.videocam_rounded : Icons.videocam_outlined,
                    color: hasVid ? theme.primaryColor : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasVid ? 'Video selected ✓' : 'Add Recipe Video',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: hasVid
                            ? theme.primaryColor
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      hasVid
                          ? _videoName ?? 'Video ready to upload'
                          : 'Optional — tap to add a cooking video',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )),
                if (hasVid)
                  GestureDetector(
                    onTap: _isLoading ? null : _removeVideo,
                    child: Icon(Icons.close,
                        color: Colors.red.shade400, size: 20),
                  )
                else
                  Icon(Icons.add_circle_outline,
                      color: theme.primaryColor, size: 22),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Upload progress ─────────────────────────────
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              margin:  const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color:        theme.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Row(children: [
                  SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      value: _imageProgress > 0
                          ? _imageProgress
                          : (_videoProgress > 0 ? _videoProgress : null),
                      strokeWidth: 2.5,
                      color:       theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ))),
                  Text(
                    _imageProgress > 0
                        ? '${(_imageProgress * 100).toInt()}%'
                        : _videoProgress > 0
                        ? '${(_videoProgress * 100).toInt()}%'
                        : '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ]),
                if (_imageProgress > 0 || _videoProgress > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _imageProgress > 0
                          ? _imageProgress : _videoProgress,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ]),
            ),

          // ── Fields ──────────────────────────────────────
          _field('Recipe Name', _nameCtrl, icon: Icons.restaurant_menu),

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: CookingTimePicker(
                initialValue: _cookingTime,
                onChanged:    (v) => setState(() => _cookingTime = v),
              ),
            ),
          ),

          _field('Ingredients (one per line)', _ingredientsCtrl,
              maxLines: 4, icon: Icons.shopping_basket_outlined),
          _field('Description', _descriptionCtrl,
              maxLines: 3, icon: Icons.description_outlined),
          _field('Steps (numbered)', _stepsCtrl,
              maxLines: 6, icon: Icons.list_alt_rounded),

          const SizedBox(height: 12),

          // Firebase Storage rules tip
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If upload stays at 0%: Firebase Console → Storage → Rules → set allow read, write: if true → Publish',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ]),
            ),

          const SizedBox(height: 12),

          // ── Post button ──────────────────────────────────
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: _isLoading
                  ? Text(_statusText.isNotEmpty
                  ? _statusText : 'Uploading...',
                  style: const TextStyle(fontSize: 15))
                  : const Text('Post Recipe',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}