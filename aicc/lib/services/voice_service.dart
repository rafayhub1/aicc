import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  VoiceService({SpeechToText? speech, FlutterTts? tts})
      : _speech = speech ?? SpeechToText(),
        _tts = tts ?? FlutterTts();

  final SpeechToText _speech;
  final FlutterTts _tts;
  bool _ready = false;

  bool get isListening => _speech.isListening;

  Future<bool> prepare() async {
    _ready = await _speech.initialize();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1);
    return _ready;
  }

  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    void Function(Object error)? onError,
  }) async {
    if (!_ready) {
      final ok = await prepare();
      if (!ok) {
        throw StateError('Speech recognition is not available on this phone.');
      }
    }
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    await stopListening();
    await _tts.stop();
  }
}
