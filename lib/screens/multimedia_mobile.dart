// lib/screens/multimedia_mobile.dart
// Loaded only on Android/iOS (not web)
// Dependencies: video_player: ^2.9.1  chewie: ^1.8.5

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerControllerWrapper {
  VideoPlayerController? _videoCtrl;
  ChewieController?      _chewieCtrl;

  Future<void> init(String url) async {
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoCtrl!.initialize();
    _chewieCtrl = ChewieController(
      videoPlayerController: _videoCtrl!,
      autoPlay:    false,
      looping:     false,
      aspectRatio: 16 / 9,
      placeholder: Container(color: Colors.black),
    );
  }

  Widget buildPlayer() {
    if (_chewieCtrl == null) {
      return Container(color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    return Chewie(controller: _chewieCtrl!);
  }

  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
  }
}