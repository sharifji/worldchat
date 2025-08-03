import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _isListening = false;
  String _currentLanguage = 'en-US';

  // Supported languages map (locale codes for both TTS and STT)
  static const Map<String, String> _supportedLanguages = {
    'en': 'en-US',  // English
    'es': 'es-ES',  // Spanish
    'fr': 'fr-FR',  // French
    'de': 'de-DE',  // German
    'zh': 'zh-CN',  // Chinese
    'ja': 'ja-JP',  // Japanese
    'ko': 'ko-KR',  // Korean
    'ru': 'ru-RU',  // Russian
    'ar': 'ar-SA',  // Arabic
    'hi': 'hi-IN',  // Hindi
  };

  Future<bool> initialize([String languageCode = 'en']) async {
    try {
      // Convert language code to locale (e.g., 'en' -> 'en-US')
      final locale = _getLocaleFromLanguageCode(languageCode);
      _currentLanguage = locale;

      // Initialize TTS
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Initialize STT
      return await _stt.initialize();
    } catch (e) {
      // Fallback to English if initialization fails
      await _tts.setLanguage('en-US');
      return await _stt.initialize();
    }
  }

  Future<void> speak(String text, {String? language}) async {
    try {
      if (language != null && language != _currentLanguage) {
        final locale = _getLocaleFromLanguageCode(language);
        await _tts.setLanguage(locale);
        _currentLanguage = locale;
      }
      await _tts.speak(text);
    } catch (e) {
      // Fallback to English if speaking fails
      await _tts.setLanguage('en-US');
      await _tts.speak(text);
    }
  }

  Future<String?> listen({String? language}) async {
    if (_isListening) return null;
    _isListening = true;

    String? result;
    final locale = language != null
        ? _getLocaleFromLanguageCode(language)
        : _currentLanguage;

    try {
      final available = await _stt.initialize();
      if (!available) return null;

      await _stt.listen(
        onResult: (stt.SpeechRecognitionResult res) {
          if (res.finalResult) {
            result = res.recognizedWords;
            _isListening = false;
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: locale,
        cancelOnError: true,
        partialResults: true,
      );

      while (_isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _isListening = false;
      // Try again with English if listening fails
      if (locale != 'en-US') {
        return await listen(language: 'en');
      }
    }

    return result;
  }

  void stop() {
    try {
      _stt.stop();
      _tts.stop();
    } catch (e) {
      // Ignore stop errors
    } finally {
      _isListening = false;
    }
  }

  bool get isListening => _isListening;

  // Helper method to convert language code to locale
  String _getLocaleFromLanguageCode(String languageCode) {
    return _supportedLanguages[languageCode] ?? 'en-US';
  }

  // Get list of supported language codes
  static List<String> get supportedLanguageCodes =>
      _supportedLanguages.keys.toList();
}