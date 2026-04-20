// lib/screens/image_cropper_stub.dart
// Stub file — loaded on web instead of image_cropper package
// image_cropper doesn't support web, so this provides no-op classes

class ImageCropper {
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    List<dynamic>? uiSettings,
  }) async => null; // no-op on web
}

class CroppedFile {
  final String path;
  const CroppedFile(this.path);
}

class AndroidUiSettings {
  const AndroidUiSettings({
    String? toolbarTitle,
    dynamic toolbarColor,
    dynamic toolbarWidgetColor,
    dynamic initAspectRatio,
    bool? lockAspectRatio,
  });
}

class IOSUiSettings {
  const IOSUiSettings({String? title});
}

class CropAspectRatioPreset {
  static const ratio16x9 = CropAspectRatioPreset._();
  const CropAspectRatioPreset._();
}