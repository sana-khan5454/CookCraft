import 'package:flutter/material.dart';

class VideoPlayerControllerWrapper {
  Future<void> init(String url) async {}   // no-op on web
  Widget buildPlayer() => Container(color: Colors.black);
  void dispose() {}
}