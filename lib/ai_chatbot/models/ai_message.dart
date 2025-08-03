import 'package:flutter/foundation.dart';

enum MessageSender { user, bot }
enum AttachmentType { none, image, pdf, text, other }

class AiMessage {
  final String content;
  final DateTime timeSent;
  final MessageSender sender;
  final String? attachmentPath;
  final AttachmentType attachmentType;
  final String? attachmentName;
  final String? languageCode;

  AiMessage({
    required this.content,
    required this.sender,
    DateTime? timeSent,
    this.attachmentPath,
    this.attachmentType = AttachmentType.none,
    this.attachmentName,
    this.languageCode,
  }) : timeSent = timeSent ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timeSent': timeSent.toIso8601String(),
      'sender': sender == MessageSender.user ? 'user' : 'bot',
      'attachmentPath': attachmentPath,
      'attachmentType': attachmentType.index,
      'attachmentName': attachmentName,
      'languageCode': languageCode,
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      content: map['content'] as String,
      timeSent: DateTime.parse(map['timeSent'] as String),
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.bot,
      attachmentPath: map['attachmentPath'] as String?,
      attachmentType: AttachmentType.values[(map['attachmentType'] as int?) ?? 0],
      attachmentName: map['attachmentName'] as String?,
      languageCode: map['languageCode'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiMessage &&
        other.content == content &&
        other.timeSent == timeSent &&
        other.sender == sender &&
        other.attachmentPath == attachmentPath &&
        other.attachmentType == attachmentType &&
        other.attachmentName == attachmentName &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      content,
      timeSent,
      sender,
      attachmentPath,
      attachmentType,
      attachmentName,
      languageCode,
    );
  }

  @override
  String toString() {
    return 'AiMessage(content: $content, timeSent: $timeSent, sender: $sender, '
        'attachmentPath: $attachmentPath, attachmentType: $attachmentType, '
        'attachmentName: $attachmentName, languageCode: $languageCode)';
  }
}