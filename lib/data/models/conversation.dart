import 'message.dart';

/// Модель беседы
class Conversation {
  final String id;
  final String modeId;
  final String submodeId;
  final ActorType actorType;
  final String? characterId;
  final int? difficultyLevel;
  final int? modelAge;
  final String language;
  final bool isActive;
  final DateTime createdAt;
  final Message? firstMessage;

  const Conversation({
    required this.id,
    required this.modeId,
    required this.submodeId,
    required this.actorType,
    this.characterId,
    this.difficultyLevel,
    this.modelAge,
    required this.language,
    required this.isActive,
    required this.createdAt,
    this.firstMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      modeId: json['mode_id'] as String,
      submodeId: json['submode_id'] as String,
      actorType: ActorType.fromString(json['actor_type'] as String),
      characterId: json['character_id'] as String?,
      difficultyLevel: json['difficulty_level'] as int?,
      modelAge: json['model_age'] as int?,
      language: json['language'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      firstMessage: json['first_message'] != null
          ? Message.fromJson(json['first_message'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isCharacterChat => actorType == ActorType.character;
  bool get isCoachChat => actorType == ActorType.coach;
}

/// Тип собеседника
enum ActorType {
  character,
  coach;

  static ActorType fromString(String value) {
    return ActorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActorType.character,
    );
  }
}
