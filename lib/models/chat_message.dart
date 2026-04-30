// lib/models/chat_message.dart
import 'summary.dart';

enum MessageRole { user, assistant }

enum InputType { text, url, voice, ocr }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final InputType inputType;
  final DateTime timestamp;
  final bool isLoading;
  final Summary? summary;
  final String? error;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.inputType,
    required this.timestamp,
    this.isLoading = false,
    this.summary,
    this.error,
  });

  ChatMessage copyWith({
    bool? isLoading,
    Summary? summary,
    String? error,
  }) =>
      ChatMessage(
        id: id,
        role: role,
        content: content,
        inputType: inputType,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
        summary: summary ?? this.summary,
        error: error ?? this.error,
      );
}
