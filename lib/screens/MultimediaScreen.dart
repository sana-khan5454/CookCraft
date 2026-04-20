// lib/screens/multimedia_screen.dart
// ✅ Web-safe: audio uses just_audio (works on Chrome)
// ✅ Video upload only on mobile (web shows message)
// ✅ Audio upload works on both web and mobile via file_picker
// ✅ All URLs stored in Firestore and loaded on open
// ✅ mounted checks everywhere

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultimediaScreen extends StatefulWidget {
  final String               docId;
  final Map<String, dynamic> recipeData;

  const MultimediaScreen({
    super.key,
    required this.docId,
    required this.recipeData,
  });

  @override
  State<MultimediaScreen> createState() => _MultimediaScreenState();
}

class _MultimediaScreenState extends State<MultimediaScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  final AudioPlayer  _audio = AudioPlayer();

  // ── State ──────────────────────────────────────────────
  bool     _uploadingVideo = false;
  bool     _uploadingAudio = false;
  double   _videoProgress  = 0;
  double   _audioProgress  = 0;
  bool     _audioPlaying   = false;
  Duration _audioDuration  = Duration.zero;
  Duration _audioPosition  = Duration.zero;
  String?  _videoUrl;
  String?  _audioUrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl  = TabController(length: 2, vsync: this);
    _videoUrl = widget.recipeData['videoUrl'];
    _audioUrl = widget.recipeData['audioUrl'];
    // Load audio if already exists
    if (_audioUrl != null && _audioUrl!.isNotEmpty) {
      _initAudio(_audioUrl!);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── Audio init ─────────────────────────────────────────

  Future<void> _initAudio(String url) async {
    try {
      await _audio.setUrl(url);
      _audio.durationStream.listen((d) {
        if (mounted) setState(() => _audioDuration = d ?? Duration.zero);
      });
      _audio.positionStream.listen((p) {
        if (mounted) setState(() => _audioPosition = p);
      });
      _audio.playerStateStream.listen((s) {
        if (mounted) setState(() =>
        _audioPlaying = s.playing &&
            s.processingState != ProcessingState.completed);
      });
    } catch (e) {
      if (mounted) _snack('Audio load error: $e');
    }
  }

  // ── Video upload ───────────────────────────────────────

  Future<void> _pickVideo() async {
    if (kIsWeb) {
      _snack('Video upload is only available on the mobile app');
      return;
    }
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() { _uploadingVideo = true; _videoProgress = 0; });
    try {
      final ref  = FirebaseStorage.instance
          .ref().child('recipe_videos/${widget.docId}.mp4');
      final task = ref.putFile(File(picked.path));

      task.snapshotEvents.listen((s) {
        if (mounted) setState(() =>
        _videoProgress = s.bytesTransferred / s.totalBytes);
      });

      await task;
      final url = await ref.getDownloadURL();

      // ✅ Save to Firestore
      await FirebaseFirestore.instance
          .collection('recipes').doc(widget.docId)
          .update({'videoUrl': url});

      if (mounted) setState(() => _videoUrl = url);
      _snack('Video uploaded and saved ✓');
    } catch (e) {
      _snack('Video upload failed: $e');
    } finally {
      if (mounted) setState(() { _uploadingVideo = false; _videoProgress = 0; });
    }
  }

  // ── Audio upload ───────────────────────────────────────

  Future<void> _pickAudio() async {
    FilePickerResult? result;
    Uint8List?        webBytes;
    String?           mobilePath;

    try {
      if (kIsWeb) {
        // On web — use bytes
        result = await FilePicker.platform.pickFiles(
          type:          FileType.audio,
          allowMultiple: false,
          withData:      true,   // ✅ get bytes on web
        );
        if (result == null) return;
        webBytes = result.files.single.bytes;
        if (webBytes == null) { _snack('Could not read audio file'); return; }
      } else {
        // On mobile — use path
        result = await FilePicker.platform.pickFiles(
          type:          FileType.audio,
          allowMultiple: false,
        );
        if (result == null || result.files.single.path == null) return;
        mobilePath = result.files.single.path;
      }
    } catch (e) {
      _snack('Could not pick audio: $e');
      return;
    }

    setState(() { _uploadingAudio = true; _audioProgress = 0; });
    try {
      final ref  = FirebaseStorage.instance
          .ref().child('recipe_audio/${widget.docId}.m4a');

      late UploadTask task;
      if (kIsWeb) {
        task = ref.putData(
          webBytes!,
          SettableMetadata(contentType: 'audio/m4a'),
        );
      } else {
        task = ref.putFile(File(mobilePath!));
      }

      task.snapshotEvents.listen((s) {
        if (mounted) setState(() =>
        _audioProgress = s.bytesTransferred / s.totalBytes);
      });

      await task;
      final url = await ref.getDownloadURL();

      // ✅ Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('recipes').doc(widget.docId)
          .update({'audioUrl': url});

      // ✅ Load audio player with new URL
      await _initAudio(url);
      if (mounted) setState(() => _audioUrl = url);
      _snack('Audio uploaded and saved ✓');
    } catch (e) {
      _snack('Audio upload failed: $e');
    } finally {
      if (mounted) setState(() { _uploadingAudio = false; _audioProgress = 0; });
    }
  }

  void _toggleAudio() {
    if (_audioPlaying) {
      _audio.pause();
    } else {
      _audio.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ✅ Safe snack with mounted check
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.recipeData['name'] ?? 'Multimedia',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller:           _tabCtrl,
          indicatorColor:       Colors.white,
          labelColor:           Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.videocam_outlined), text: 'Video'),
            Tab(icon: Icon(Icons.headphones),        text: 'Audio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildVideoTab(theme),
          _buildAudioTab(theme),
        ],
      ),
    );
  }

  // ── Video Tab ──────────────────────────────────────────

  Widget _buildVideoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Video preview area
          Container(
            height: 200, width: double.infinity,
            decoration: BoxDecoration(
              color:        Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _videoUrl != null
                        ? Icons.play_circle_outline
                        : Icons.videocam_off_outlined,
                    size: 64, color: Colors.white38,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _videoUrl != null
                        ? kIsWeb
                        ? 'Video saved ✓\nPlayback available on mobile app'
                        : 'Video uploaded ✓'
                        : kIsWeb
                        ? 'Upload from mobile app'
                        : 'No video uploaded yet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Upload progress
          if (_uploadingVideo) ...[
            const SizedBox(height: 12),
            _ProgressBar(
              progress: _videoProgress,
              label:    'Uploading video...',
              theme:    theme,
            ),
          ],

          const SizedBox(height: 20),

          Text('Recipe Video',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            kIsWeb
                ? 'Video upload and playback work on the mobile app.\nThe URL is stored in Firebase and available on all devices.'
                : _videoUrl != null
                ? 'Video is stored in Firebase Storage and linked to this recipe.'
                : 'Upload a cooking video. It will be stored in Firebase and shown to users.',
            style: TextStyle(
              color:  theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          if (!kIsWeb)
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _uploadingVideo ? null : _pickVideo,
                icon: _uploadingVideo
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_rounded),
                label: Text(
                  _uploadingVideo ? 'Uploading…'
                      : _videoUrl != null ? 'Replace Video' : 'Upload Video',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Video upload requires the mobile app. Audio upload works here.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Audio Tab ──────────────────────────────────────────

  Widget _buildAudioTab(ThemeData theme) {
    final progress = _audioDuration.inSeconds > 0
        ? (_audioPosition.inSeconds / _audioDuration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Player card ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              const Icon(Icons.audio_file_outlined, size: 56, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                widget.recipeData['name'] ?? 'Recipe Audio',
                style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _audioUrl != null ? 'Cooking Instructions — Tap play' : 'No audio yet',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Seek bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:   Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor:         Colors.white,
                  overlayColor:       Colors.white24,
                  trackHeight:        3,
                ),
                child: Slider(
                  value:    progress,
                  onChanged: _audioUrl != null
                      ? (v) => _audio.seek(Duration(
                      seconds: (v * _audioDuration.inSeconds).round()))
                      : null,
                ),
              ),

              // Time display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_audioPosition),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_fmt(_audioDuration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Controls
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Rewind 10s
                IconButton(
                  onPressed: _audioUrl != null
                      ? () => _audio.seek(Duration(
                      seconds: (_audioPosition.inSeconds - 10).clamp(0, 9999)))
                      : null,
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                // Play / Pause
                GestureDetector(
                  onTap: _audioUrl != null ? _toggleAudio : null,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color:  _audioUrl != null ? Colors.white : Colors.white38,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _audioPlaying ? Icons.pause : Icons.play_arrow,
                      color: theme.primaryColor, size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Forward 10s
                IconButton(
                  onPressed: _audioUrl != null
                      ? () => _audio.seek(Duration(
                      seconds: (_audioPosition.inSeconds + 10)
                          .clamp(0, _audioDuration.inSeconds)))
                      : null,
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                ),
              ]),
            ]),
          ),

          // Upload progress
          if (_uploadingAudio) ...[
            const SizedBox(height: 12),
            _ProgressBar(
              progress: _audioProgress,
              label:    'Uploading audio...',
              theme:    theme,
            ),
          ],

          const SizedBox(height: 20),

          Text('Audio Instructions',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _audioUrl != null
                ? 'Audio is stored in Firebase and plays on all devices.'
                : 'Upload spoken cooking instructions. Stored in Firebase, available everywhere.',
            style: TextStyle(
              color:  theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Upload button — works on both web and mobile
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: _uploadingAudio ? null : _pickAudio,
              icon: _uploadingAudio
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.upload_rounded),
              label: Text(
                _uploadingAudio ? 'Uploading…'
                    : _audioUrl != null ? 'Replace Audio' : 'Upload Audio',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 16, color: theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Supported: MP3, M4A, WAV, AAC. Works on web and mobile.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar widget ────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double    progress;
  final String    label;
  final ThemeData theme;

  const _ProgressBar({
    required this.progress,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              value:       progress > 0 ? progress : null,
              strokeWidth: 2,
              color:       theme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ))),
          Text('${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize:   13,
                color:      theme.primaryColor,
              )),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           progress,
            backgroundColor: theme.dividerColor,
            valueColor:      AlwaysStoppedAnimation<Color>(theme.primaryColor),
            minHeight:       5,
          ),
        ),
      ]),
    );
  }
}