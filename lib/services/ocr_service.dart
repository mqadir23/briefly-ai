// lib/services/ocr_service.dart
//
// ── Real OCR setup (Android / iOS) ───────────────────────────────────────────
// 1. Add to pubspec.yaml:
//      google_mlkit_text_recognition: ^0.13.0
//      camera: ^0.10.5+9
// 2. android/app/build.gradle  →  minSdkVersion 21
// 3. android/app/src/main/AndroidManifest.xml:
//      <uses-permission android:name="android.permission.CAMERA"/>
// 4. ios/Runner/Info.plist:
//      <key>NSCameraUsageDescription</key>
//      <string>Briefly AI uses the camera to scan printed text.</string>
// 5. Uncomment the real implementation below and delete the stub.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  /// True once the real MLKit path is enabled.
  bool get isAvailable => true;

  /// Extracts text from [imagePath] (absolute path from camera / image_picker).
  /// Returns extracted text, or null when unavailable / failed.
  Future<String?> extractTextFromImage(String imagePath) async {
    final recognizer = TextRecognizer();
    final inputImage  = InputImage.fromFilePath(imagePath);
    try {
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      await recognizer.close();
      return null;
    }
  }
}
