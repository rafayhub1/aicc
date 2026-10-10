import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceService {
  VoiceService({AudioRecorder? recorder, FlutterTts? tts})
      : _recorder = recorder ?? AudioRecorder(),
        _tts = tts ?? FlutterTts();

  final AudioRecorder _recorder;
  final FlutterTts _tts;
  bool _recording = false;

  bool get isRecording => _recording;

  Future<bool> prepare() async {
    final allowed = await _recorder.hasPermission();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1);
    return allowed;
  }

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission was denied.');
    }
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/aicc-speech.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _recording = true;
  }

  Future<String?> stopRecording() async {
    if (!_recording && !await _recorder.isRecording()) return null;
    _recording = false;
    return _recorder.stop();
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    if (_recording) await stopRecording();
    await _tts.stop();
    await _recorder.dispose();
  }
}
