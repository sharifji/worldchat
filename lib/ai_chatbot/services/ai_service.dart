import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../models/ai_message.dart';
import '../utils/ai_constants.dart';
import '../utils/ai_prompt_templates.dart';

class AiService {
  final translator = GoogleTranslator();

  Future<String> getAiResponse(List<AiMessage> messages, String currentLanguage) async {
    try {
      final lastUserMessage = messages.lastWhere(
            (msg) => msg.sender == MessageSender.user,
        orElse: () => AiMessage(content: '', sender: MessageSender.user),
      );

      // Handle language learning requests
      if (lastUserMessage.content.toLowerCase().contains('how do you say') ||
          lastUserMessage.content.toLowerCase().contains('translate')) {
        return await _handleTranslationRequest(lastUserMessage.content, currentLanguage);
      }

      if (lastUserMessage.content.toLowerCase().contains('practice') &&
          lastUserMessage.content.toLowerCase().contains('language')) {
        return _createLanguagePracticeExercise(currentLanguage);
      }

      // Check for search requests
      if (lastUserMessage.content.toLowerCase().contains('search') ||
          lastUserMessage.content.toLowerCase().contains('find')) {
        final query = Uri.encodeComponent(lastUserMessage.content
            .replaceAll('search', '')
            .replaceAll('find', '')
            .trim());
        return '${AiConstants.searchResultPrefix}I found these results for "${lastUserMessage.content}": '
            '[SEARCH:$query]';
      }

      // Generate localized response
      return await _generateLocalResponse(lastUserMessage.content, currentLanguage);
    } catch (e) {
      throw Exception('Error processing request: $e');
    }
  }

  Future<String> _generateLocalResponse(String query, String currentLanguage) async {
    // Simple local responses for common queries
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('hello') || lowerQuery.contains('hi')) {
      return await _translateIfNeeded('Hello! How can I help you today?', currentLanguage);
    }

    if (lowerQuery.contains('weather')) {
      final message = '${AiConstants.searchResultPrefix}For accurate weather information, I can search online for you. '
          'Would you like me to check the weather for your location? [SEARCH:current weather]';
      return await _translateIfNeeded(message, currentLanguage);
    }

    if (lowerQuery.contains('news')) {
      final message = '${AiConstants.searchResultPrefix}Here are some current news headlines: [SEARCH:latest news]';
      return await _translateIfNeeded(message, currentLanguage);
    }

    // Default response for other queries
    final message = '${AiConstants.searchResultPrefix}I can help you find information about that. '
        'Would you like me to search online for "$query"? [SEARCH:$query]';
    return await _translateIfNeeded(message, currentLanguage);
  }

  Future<String> _handleTranslationRequest(String query, String currentLanguage) async {
    try {
      // Extract phrase to translate
      final parts = query.split(' in ');
      var phrase = parts.first
          .replaceAll('how do you say', '')
          .replaceAll('translate', '')
          .trim();

      String targetLanguage = currentLanguage;
      if (parts.length > 1) {
        targetLanguage = _getLanguageCode(parts.last.trim()) ?? currentLanguage;
      }

      if (phrase.isEmpty) {
        return 'Please tell me what you\'d like to translate.';
      }

      // Translate the phrase
      final translation = await translator.translate(phrase, to: targetLanguage);

      return 'In ${_getLanguageName(targetLanguage)}, "$phrase" is: '
          '${translation.text}\n\n'
          'Pronunciation: [PRONOUNCE:${translation.text}]';
    } catch (e) {
      return 'Sorry, I couldn\'t complete the translation. Please try again.';
    }
  }

  String _createLanguagePracticeExercise(String language) {
    final languageName = _getLanguageName(language);
    final exercises = {
      'beginner': 'Let\'s start with basic greetings. Try saying: "Hello" in $languageName',
      'intermediate': 'How about this sentence: "Where is the nearest restaurant?" in $languageName',
      'advanced': 'Try this complex sentence: "I would like to improve my speaking skills in $languageName"'
    };

    return 'Great! Let\'s practice $languageName. ${exercises['beginner']}';
  }

  Future<String> performWebSearch(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AiConstants.searchEngineUrl}$query'),
      );

      if (response.statusCode == 200) {
        return 'I found results for "$query". You can view them here: '
            '${AiConstants.searchEngineUrl}$query';
      } else {
        throw Exception('Failed to perform search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error performing search: $e');
    }
  }

  Future<String> _translateIfNeeded(String text, String targetLanguage) async {
    if (targetLanguage == 'en') return text;

    try {
      final translation = await translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      return text; // Return original text if translation fails
    }
  }

  String _getLanguageName(String code) {
    final names = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ru': 'Russian',
      'ar': 'Arabic',
      'hi': 'Hindi',
    };
    return names[code] ?? 'this language';
  }

  String? _getLanguageCode(String name) {
    final codes = {
      'english': 'en',
      'spanish': 'es',
      'french': 'fr',
      'german': 'de',
      'chinese': 'zh',
      'japanese': 'ja',
      'korean': 'ko',
      'russian': 'ru',
      'arabic': 'ar',
      'hindi': 'hi',
    };
    return codes[name.toLowerCase()];
  }
}