import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant }

class MessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.user(String content) => MessageModel(
        id: const Uuid().v4(),
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory MessageModel.assistant(String content) => MessageModel(
        id: const Uuid().v4(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );
}
