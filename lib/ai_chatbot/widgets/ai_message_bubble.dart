import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../controllers/ai_chat_controller.dart';

class AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  final bool isUser;

  const AiMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<AiChatController>(context, listen: false);

    return GestureDetector(
      onTap: () {
        if (!isUser) {
          controller.speak(message.content);
        }
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isUser
                ? theme.primaryColor
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12.0),
              topRight: const Radius.circular(12.0),
              bottomLeft: isUser
                  ? const Radius.circular(12.0)
                  : const Radius.circular(0.0),
              bottomRight: isUser
                  ? const Radius.circular(0.0)
                  : const Radius.circular(12.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 2.0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Language indicator for non-English messages
              if (message.languageCode != null && message.languageCode != 'en')
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUser
                          ? _withOpacity(Colors.white, 0.2)
                          : _withOpacity(theme.primaryColor, 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getLanguageName(message.languageCode!),
                      style: TextStyle(
                        color: isUser ? Colors.white : theme.primaryColor,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (message.attachmentType != AttachmentType.none)
                _buildAttachmentPreview(context, message),
              if (message.content.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: message.attachmentType != AttachmentType.none ? 8.0 : 0.0,
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser && message.content.isNotEmpty)
                    Icon(
                      Icons.volume_up,
                      size: 12.0,
                      color: isUser
                          ? _withOpacity(Colors.white, 0.7)
                          : _withOpacity(theme.colorScheme.onSurface, 0.6),
                    ),
                  if (!isUser && message.content.isNotEmpty)
                    const SizedBox(width: 4.0),
                  Text(
                    _formatTime(message.timeSent),
                    style: TextStyle(
                      color: isUser
                          ? _withOpacity(Colors.white, 0.7)
                          : _withOpacity(theme.colorScheme.onSurface, 0.6),
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _withOpacity(Color color, double opacity) {
    return Color.fromRGBO(
      (color.red * 255.0).round() & 0xff,
      (color.green * 255.0).round() & 0xff,
      (color.blue * 255.0).round() & 0xff,
      opacity,
    );
  }

  String _getLanguageName(String languageCode) {
    const languageNames = {
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
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  Widget _buildAttachmentPreview(BuildContext context, AiMessage message) {
    final theme = Theme.of(context);
    final bgColor = isUser
        ? _withOpacity(theme.primaryColor, 0.8)
        : _withOpacity(theme.colorScheme.secondaryContainer, 0.8);

    switch (message.attachmentType) {
      case AttachmentType.image:
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _withOpacity(theme.dividerColor, 0.2),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(message.attachmentPath!),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: bgColor,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      case AttachmentType.pdf:
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Implement PDF viewer
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.attachmentName ?? 'PDF Document',
                    style: TextStyle(
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case AttachmentType.text:
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Implement text file viewer
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.attachmentName ?? 'Text Document',
                    style: TextStyle(
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case AttachmentType.other:
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Implement file opener
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.attachmentName ?? 'File Attachment',
                    style: TextStyle(
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}