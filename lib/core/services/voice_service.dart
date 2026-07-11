import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceService {
  VoiceService._internal();
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechAvailable = false;
  bool get isAvailable => _speechAvailable;

  Future<bool> init() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => print('Speech error: ${error.errorMsg}'),
      onStatus: (status) => print('Speech status: $status'),
    );

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    return _speechAvailable;
  }

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> checkMicPermissionPermanentlyDenied() async {
    return await Permission.microphone.isPermanentlyDenied;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function() onListeningDone,
  }) async {
    if (!_speechAvailable) {
      final ok = await init();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3), // auto-stop after 3s silence
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  Future<void> speak(String text) async {
    // Strip markdown before speaking so TTS doesn't read out "asterisk asterisk"
    final cleanText = _stripMarkdown(text);
    await _tts.speak(cleanText);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1');
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}