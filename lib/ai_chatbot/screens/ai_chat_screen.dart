import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worldchat/ai_chatbot/models/ai_message.dart';
import '../controllers/ai_chat_controller.dart';
import '../services/ai_service.dart';
import '../widgets/ai_message_bubble.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AiChatController>(context, listen: false);
      controller.initializeVoice();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSearchRequest(String query) async {
    final controller = Provider.of<AiChatController>(context, listen: false);
    final aiService = AiService();

    controller.setTyping(true);

    try {
      // Pass both the messages and the query to getAiResponse
      final response = await aiService.getAiResponse(controller.messages, query);

      if (response.contains('[SEARCH:')) {
        final searchQuery = response.split('[SEARCH:')[1].split(']')[0];
        final searchResults = await aiService.performWebSearch(searchQuery);
        await controller.sendMessage(searchResults, isUser: false);
      } else {
        await controller.sendMessage(response, isUser: false);
      }
    } catch (e) {
      await controller.sendMessage(
        'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
      );
    } finally {
      controller.setTyping(false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isNotEmpty) {
      final controller = Provider.of<AiChatController>(context, listen: false);
      final message = _textController.text.trim();
      await controller.sendMessage(message, isUser: true);
      _textController.clear();
      _scrollToBottom();
      await _handleSearchRequest(message);
    }
  }

  void _toggleVoiceInput() {
    final controller = Provider.of<AiChatController>(context, listen: false);
    if (controller.isListening) {
      controller.stopListening();
    } else {
      controller.startListening();
      _textFieldFocusNode.unfocus();
    }
  }

  Future<void> _attachFile() async {
    final controller = Provider.of<AiChatController>(context, listen: false);
    _textFieldFocusNode.unfocus();
    await controller.attachFile();
    _scrollToBottom();
  }

  void _showLanguageSelector() {
    final controller = Provider.of<AiChatController>(context, listen: false);
    final currentLanguage = controller.currentLanguage;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView(
                children: controller.availableLanguages.entries.map((entry) {
                  final isSelected = currentLanguage == entry.value;
                  return ListTile(
                    title: Text(entry.key),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () {
                      controller.setLanguage(entry.value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AiChatController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
            tooltip: 'Change Language',
          ),
          IconButton(
            icon: Icon(
              controller.isListening ? Icons.mic_off : Icons.mic,
              color: controller.isListening ? Colors.red : Colors.white,
            ),
            onPressed: _toggleVoiceInput,
            tooltip: 'Voice Input',
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.isListening)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final message = controller.messages[index];
                return AiMessageBubble(
                  message: message,
                  isUser: message.sender == MessageSender.user,
                );
              },
            ),
          ),
          if (controller.isTyping)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _attachFile,
                  tooltip: 'Attach file',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFieldFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: controller.isListening
            ? Colors.red
            : theme.primaryColor,
        onPressed: _toggleVoiceInput,
        tooltip: 'Voice Input',
        child: Icon(
          controller.isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}