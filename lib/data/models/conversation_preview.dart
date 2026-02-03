import 'conversation.dart';

/// Превью беседы для экрана истории
class ConversationPreview {
  final String id;
  final String submodeId;
  final ActorType actorType;
  final String? characterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final int messageCount;

  const ConversationPreview({
    required this.id,
    required this.submodeId,
    required this.actorType,
    this.characterId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    required this.messageCount,
  });

  factory ConversationPreview.fromJson(Map<String, dynamic> json) {
    return ConversationPreview(
      id: json['id'] as String,
      submodeId: json['submode_id'] as String,
      actorType: ActorType.fromString(json['actor_type'] as String),
      characterId: json['character_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessage: json['last_message'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }
}
