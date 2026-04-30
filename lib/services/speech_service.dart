// lib/services/speech_service.dart
//
// ANDROID SETUP REQUIRED:
//   Add to android/app/src/main/AndroidManifest.xml (inside <manifest>):
//     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//
// iOS SETUP REQUIRED:
//   Add to ios/Runner/Info.plist:
//     <key>NSMicrophoneUsageDescription</key>
//     <string>Briefly AI needs microphone access for voice input.</string>
//     <key>NSSpeechRecognitionUsageDescription</key>
//     <string>Briefly AI uses speech recognition to convert your voice to text.</string>

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();
  bool _ready = false;

  /// Whether the service is currently listening.
  bool get isListening => _stt.isListening;

  /// Whether the service was successfully initialised.
  /// Always false on web (the plugin doesn't support it).
  bool get isAvailable => _ready && !kIsWeb;

  /// Initialises the speech recogniser and requests microphone permission.
  /// Returns true if ready to listen.
  Future<bool> initialize() async {
    if (kIsWeb) return false;
    if (_ready) return true;
    _ready = await _stt.initialize(
      onError: (e) => debugPrint('[SpeechService] error: ${e.errorMsg}'),
      onStatus: (s) => debugPrint('[SpeechService] status: $s'),
    );
    return _ready;
  }

  /// Starts listening. [onResult] is called with every partial and final result.
  /// [isFinal] is true when the recogniser has reached a confident conclusion.
  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
  }) async {
    if (!_ready && !(await initialize())) return;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 60),
    );
  }

  /// Stops listening gracefully (fires one final result callback).
  Future<void> stop() => _stt.stop();

  /// Cancels listening immediately without a final callback.
  Future<void> cancel() => _stt.cancel();
}
