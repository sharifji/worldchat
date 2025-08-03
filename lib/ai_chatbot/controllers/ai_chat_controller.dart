import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:translator/translator.dart';
import '../models/ai_message.dart';
import '../models/ai_chat_history.dart';
import '../services/ai_local_storage.dart';
import '../services/voice_service.dart';
import '../services/file_processing_service.dart';

class AiChatController with ChangeNotifier {
  final AiLocalStorage _storage = AiLocalStorage();
  final VoiceService _voiceService = VoiceService();
  final FileProcessingService _fileService = FileProcessingService();
  final translator = GoogleTranslator();

  List<AiMessage> _messages = [];
  List<AiChatHistory> _chatHistory = [];
  bool _isTyping = false;
  bool _isListening = false;
  String _currentLanguage = 'en';

  // Supported languages map
  final Map<String, String> _languageCodes = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Chinese': 'zh',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Russian': 'ru',
    'Arabic': 'ar',
    'Hindi': 'hi',
  };

  List<AiMessage> get messages => _messages;
  List<AiChatHistory> get chatHistory => _chatHistory;
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  String get currentLanguage => _currentLanguage;
  Map<String, String> get availableLanguages => _languageCodes;

  AiChatController() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadChatHistory();
    await _loadLanguagePreference();
    await initializeVoice();
  }

  Future<void> _loadLanguagePreference() async {
    final savedLanguage = await _storage.loadSetting('language');
    if (savedLanguage != null && _languageCodes.containsValue(savedLanguage)) {
      _currentLanguage = savedLanguage;
      notifyListeners();
    }
  }

  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  Future<void> _loadChatHistory() async {
    _chatHistory = await _storage.loadChatHistory();
    notifyListeners();
  }

  Future<void> initializeVoice() async {
    await _voiceService.initialize();
  }

  Future<void> startListening() async {
    _isListening = true;
    notifyListeners();

    final result = await _voiceService.listen(language: _currentLanguage);
    _isListening = false;
    notifyListeners();

    if (result != null && result.isNotEmpty) {
      await sendMessage(result, isUser: true);
    }
  }

  void stopListening() {
    _voiceService.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_languageCodes.containsValue(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
      await _storage.saveSetting('language', languageCode);
    }
  }

  Future<void> detectAndSetLanguage(String text) async {
    try {
      final detection = await translator.translate(text, to: 'en');
      if (_languageCodes.containsValue(detection.sourceLanguage.code)) {
        await setLanguage(detection.sourceLanguage.code);
      }
    } catch (e) {
      debugPrint('Language detection error: $e');
    }
  }

  Future<String> translateText(String text, {String? targetLanguage}) async {
    if (targetLanguage == null || targetLanguage == _currentLanguage) {
      return text;
    }

    try {
      final translation = await translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  Future<void> sendMessage(String message, {required bool isUser}) async {
    if (isUser) {
      await detectAndSetLanguage(message);
    }

    _addMessage(
      content: message,
      sender: isUser ? MessageSender.user : MessageSender.bot,
    );

    if (isUser) {
      _isTyping = true;
      notifyListeners();

      try {
        String response = await _getLocalResponse(message);

        if (_currentLanguage != 'en') {
          final englishResponse = await _getLocalResponse(
              await translateText(message, targetLanguage: 'en')
          );
          response = '$response\n\n(English: $englishResponse)';
        }

        _addMessage(
          content: response,
          sender: MessageSender.bot,
        );
        await _voiceService.speak(response, language: _currentLanguage);

        if (_messages.length == 2) {
          final chat = AiChatHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.length > 20
                ? '${message.substring(0, 20)}...'
                : message,
            messages: List.from(_messages),
          );
          await _storage.addChatToHistory(chat);
          _chatHistory.insert(0, chat);
        }
      } catch (e) {
        final errorMsg = 'Sorry, I encountered an error: $e';
        _addMessage(
          content: errorMsg,
          sender: MessageSender.bot,
        );
        await _voiceService.speak(errorMsg, language: _currentLanguage);
      } finally {
        _isTyping = false;
        notifyListeners();
      }
    }
  }

  Future<void> attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        final savedFile = await _fileService.saveFileToLocalStorage(file, fileName);
        final fileContent = await _fileService.extractTextFromFile(file, fileName);

        final attachmentType = _getAttachmentType(fileName);
        _addMessage(
          content: 'I uploaded a file: $fileName',
          sender: MessageSender.user,
          attachmentPath: savedFile.path,
          attachmentType: attachmentType,
          attachmentName: fileName,
        );

        await _processFileContent(fileContent, fileName);
      }
    } catch (e) {
      _addMessage(
        content: 'Error uploading file: ${e.toString()}',
        sender: MessageSender.bot,
      );
    }
  }

  AttachmentType _getAttachmentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return AttachmentType.image;
    } else if (extension == 'pdf') {
      return AttachmentType.pdf;
    } else if (['txt', 'doc', 'docx', 'md'].contains(extension)) {
      return AttachmentType.text;
    } else {
      return AttachmentType.other;
    }
  }

  Future<void> _processFileContent(String content, String fileName) async {
    _isTyping = true;
    notifyListeners();

    try {
      if (content.contains('[SEARCH:')) {
        final searchQuery = content.split('[SEARCH:')[1].split(']')[0];
        final response = await _scrapeWebAnswer(searchQuery);
        _addMessage(
          content: response,
          sender: MessageSender.bot,
        );
      } else {
        final summary = content.length > 200
            ? '${content.substring(0, 200)}...'
            : content;
        _addMessage(
          content: 'I found this in the file "$fileName":\n\n$summary',
          sender: MessageSender.bot,
        );
      }
    } catch (e) {
      _addMessage(
        content: 'Error processing file content: ${e.toString()}',
        sender: MessageSender.bot,
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<String> _getLocalResponse(String query) async {
    try {
      final predefined = _getPredefinedResponse(query);
      if (predefined != null) return predefined;

      return await _scrapeWebAnswer(query);
    } catch (e) {
      return "I couldn't find an answer to that question. Please try asking something else.";
    }
  }

  String? _getPredefinedResponse(String query) {
    final responses = {
      'hello': 'Hello there! How can I help you today?',
      'hi': 'Hi! What can I do for you?',
      'what is your name': 'I am your local AI assistant',
      'who created you': 'I was created by a developer to help you',
      'how are you': 'I\'m functioning well, thank you for asking!',
      'what can you do': 'I can answer questions, process files, and have conversations with you',
      'thank you': 'You\'re welcome! Is there anything else you need?',
      'goodbye': 'Goodbye! Feel free to come back if you have more questions.',
    };

    final lowerQuery = query.toLowerCase();

    if (responses.containsKey(lowerQuery)) {
      return responses[lowerQuery]!;
    }

    for (final key in responses.keys) {
      if (lowerQuery.contains(key)) {
        return responses[key]!;
      }
    }

    return null;
  }

  Future<String> _scrapeWebAnswer(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro&explaintext&titles=$encodedQuery';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']['pages'];
        final page = pages.values.first;

        if (page['extract'] != null) {
          final extract = page['extract'] as String;
          return _summarizeExtract(extract);
        }
      }
      return 'I found no information about "$query" on Wikipedia.';
    } catch (e) {
      return 'Sorry, I couldn\'t fetch information online. Please try asking something else.';
    }
  }

  String _summarizeExtract(String extract) {
    final firstParagraph = extract.split('\n')[0];
    if (firstParagraph.length > 200) {
      return '${firstParagraph.substring(0, 200)}...';
    }
    return firstParagraph;
  }

  void _addMessage({
    required String content,
    required MessageSender sender,
    String? attachmentPath,
    AttachmentType attachmentType = AttachmentType.none,
    String? attachmentName,
  }) {
    _messages.add(AiMessage(
      content: content,
      sender: sender,
      timeSent: DateTime.now(),
      attachmentPath: attachmentPath,
      attachmentType: attachmentType,
      attachmentName: attachmentName,
    ));
    notifyListeners();
  }

  Future<void> loadChatFromHistory(AiChatHistory chat) async {
    _messages = List.from(chat.messages);
    notifyListeners();
  }

  void clearCurrentChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> deleteChatHistory(String id) async {
    _chatHistory.removeWhere((chat) => chat.id == id);
    await _storage.saveChatHistory(_chatHistory);
    notifyListeners();
  }

  Future<void> speak(String content) async {
    await _voiceService.speak(content, language: _currentLanguage);
  }
}