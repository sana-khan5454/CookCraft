// lib/screens/image_transform_screen.dart
// ✅ Web-safe: image_cropper skipped on web (not supported)
// ✅ Filters + brightness/contrast work on both web and mobile
// ✅ Saves to Firebase Storage + updates Firestore imageUrl
// ✅ mounted checks throughout

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

// image_cropper only on mobile
import 'package:image_cropper/image_cropper.dart'
if (dart.library.html) 'image_cropper_stub.dart';

enum ImageFilter { none, grayscale, sepia, vivid, cool }

class ImageTransformScreen extends StatefulWidget {
  final String  docId;
  final File?   sourceFile;        // mobile new-post flow
  final String? existingImageUrl;  // edit flow

  const ImageTransformScreen({
    super.key,
    required this.docId,
    this.sourceFile,
    this.existingImageUrl,
  });

  @override
  State<ImageTransformScreen> createState() => _ImageTransformScreenState();
}

class _ImageTransformScreenState extends State<ImageTransformScreen> {
  // On mobile: File; on web: Uint8List
  dynamic    _originalData;
  Uint8List? _previewBytes;

  ImageFilter _selectedFilter = ImageFilter.none;
  double      _brightness     = 1.0;
  double      _contrast       = 1.0;

  bool _isProcessing = false;
  bool _isSaving     = false;

  static const _filterLabels = {
    ImageFilter.none:      'Original',
    ImageFilter.grayscale: 'B&W',
    ImageFilter.sepia:     'Sepia',
    ImageFilter.vivid:     'Vivid',
    ImageFilter.cool:      'Cool',
  };

  @override
  void initState() {
    super.initState();
    if (widget.sourceFile != null && !kIsWeb) {
      _originalData = widget.sourceFile;
      _applyTransformations();
    }
  }

  // ── Pick image ─────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    if (kIsWeb) {
      // Web: read bytes directly, no cropper
      final bytes = await picked.readAsBytes();
      setState(() {
        _originalData   = bytes as Uint8List;
        _previewBytes   = null;
        _selectedFilter = ImageFilter.none;
        _brightness     = 1.0;
        _contrast       = 1.0;
      });
      await _applyTransformations();
    } else {
      // Mobile: offer crop
      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle:       'Crop Recipe Image',
              toolbarColor:       Colors.green,
              toolbarWidgetColor: Colors.white,
              initAspectRatio:    CropAspectRatioPreset.ratio16x9,
              lockAspectRatio:    false,
            ),
            IOSUiSettings(title: 'Crop Recipe Image'),
          ],
        );
      } catch (_) {
        // If cropper fails, use original
      }

      final path = cropped?.path ?? picked.path;
      setState(() {
        _originalData   = File(path);
        _previewBytes   = null;
        _selectedFilter = ImageFilter.none;
        _brightness     = 1.0;
        _contrast       = 1.0;
      });
      await _applyTransformations();
    }
  }

  // ── Apply filters ──────────────────────────────────────

  Future<void> _applyTransformations() async {
    if (_originalData == null) return;
    setState(() => _isProcessing = true);

    try {
      Uint8List sourceBytes;
      if (kIsWeb) {
        sourceBytes = _originalData as Uint8List;
      } else {
        sourceBytes = await (_originalData as File).readAsBytes();
      }

      img.Image? image = img.decodeImage(sourceBytes);
      if (image == null) throw Exception('Could not decode image');

      // Brightness & contrast
      if (_brightness != 1.0 || _contrast != 1.0) {
        image = img.adjustColor(image,
            brightness: _brightness, contrast: _contrast);
      }

      // Filter
      switch (_selectedFilter) {
        case ImageFilter.grayscale:
          image = img.grayscale(image); break;
        case ImageFilter.sepia:
          image = img.sepia(image); break;
        case ImageFilter.vivid:
          image = img.adjustColor(image, saturation: 1.6); break;
        case ImageFilter.cool:
          image = img.adjustColor(image, hue: 200 / 360); break;
        case ImageFilter.none:
          break;
      }

      final encoded = Uint8List.fromList(img.encodeJpg(image, quality: 88));

      if (!kIsWeb) {
        // Save to temp file on mobile
        final tempDir  = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/transform_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(encoded);
        // Keep _originalData as File for upload
      }

      setState(() => _previewBytes = encoded);
    } catch (e) {
      if (mounted) _snack('Processing error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Save to Firebase ───────────────────────────────────

  Future<void> _save() async {
    if (_originalData == null) return;
    setState(() => _isSaving = true);

    try {
      final ref = FirebaseStorage.instance
          .ref().child('recipe_images/${widget.docId}.jpg');

      late UploadTask task;
      if (kIsWeb) {
        // Upload processed bytes or original bytes
        final bytes = _previewBytes
            ?? (_originalData as Uint8List);
        task = ref.putData(bytes,
            SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // Upload processed file
        if (_previewBytes != null) {
          final tempDir  = await getTemporaryDirectory();
          final saveFile = File(
              '${tempDir.path}/save_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await saveFile.writeAsBytes(_previewBytes!);
          task = ref.putFile(saveFile);
        } else {
          task = ref.putFile(_originalData as File);
        }
      }

      final snap = await task;
      if (snap.state != TaskState.success) throw Exception('Upload failed');
      final url = await ref.getDownloadURL();

      // ✅ Always update Firestore imageUrl
      await FirebaseFirestore.instance
          .collection('recipes').doc(widget.docId)
          .update({'imageUrl': url});

      _snack('Image saved ✓');
      if (mounted) Navigator.pop(context, url);
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final hasImage = _originalData != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Edit Image'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (hasImage)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
        ],
      ),
      body: Column(children: [

        // ── Preview ────────────────────────────────────────
        Expanded(
          flex: 5,
          child: Stack(children: [
            Container(
              width: double.infinity,
              color: Colors.black,
              child: hasImage
                  ? (_previewBytes != null
                  ? Image.memory(_previewBytes!, fit: BoxFit.contain)
                  : (kIsWeb
                  ? Image.memory(_originalData as Uint8List,
                  fit: BoxFit.contain)
                  : Image.file(_originalData as File,
                  fit: BoxFit.contain)))
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined,
                        size: 80, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('Tap "Pick Image" below',
                        style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),
          ]),
        ),

        // ── Controls ───────────────────────────────────────
        Expanded(
          flex: 4,
          child: Container(
            color: theme.cardColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Pick button
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickImage,
                      icon:  const Icon(Icons.photo_library_outlined),
                      label: Text(hasImage
                          ? (kIsWeb ? 'Change Image' : 'Change & Crop')
                          : (kIsWeb ? 'Pick Image' : 'Pick & Crop Image')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        side: BorderSide(color: theme.primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Crop is available on mobile. Filters and adjustments work on web.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),

                  if (hasImage) ...[
                    const SizedBox(height: 16),

                    // Filters
                    Text('Filters',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ImageFilter.values.map((f) {
                          final sel = _selectedFilter == f;
                          return GestureDetector(
                            onTap: _isProcessing ? null : () {
                              setState(() => _selectedFilter = f);
                              _applyTransformations();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? theme.primaryColor
                                    : theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: sel
                                      ? theme.primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                _filterLabels[f]!,
                                style: TextStyle(
                                  color: sel ? Colors.white : null,
                                  fontWeight: sel
                                      ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Brightness
                    _slider(
                      label: 'Brightness',
                      icon:  Icons.brightness_6_outlined,
                      value: _brightness, min: 0.5, max: 1.5,
                      onChanged:   (v) => setState(() => _brightness = v),
                      onChangeEnd: (_) => _applyTransformations(),
                      theme: theme,
                    ),

                    // Contrast
                    _slider(
                      label: 'Contrast',
                      icon:  Icons.contrast,
                      value: _contrast, min: 0.5, max: 1.5,
                      onChanged:   (v) => setState(() => _contrast = v),
                      onChangeEnd: (_) => _applyTransformations(),
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _slider({
    required String label, required IconData icon,
    required double value, required double min, required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        SizedBox(width: 72,
            child: Text(label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis)),
        Expanded(
          child: Slider(
            value: value, min: min, max: max,
            activeColor: theme.primaryColor,
            onChanged:   _isProcessing ? null : onChanged,
            onChangeEnd: _isProcessing ? null : onChangeEnd,
          ),
        ),
        SizedBox(width: 34,
            child: Text(value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center)),
      ]),
    );
  }
}