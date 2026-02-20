import 'training_meta.dart';

/// Превью одного тренировочного разговора для экрана истории
class TrainingConversationPreview {
  final String conversationId;
  final String submodeId;
  final int? difficultyLevel;
  final DateTime createdAt;
  // Результат evaluate — null если ещё не оценён
  final String? attemptId;
  final String? status; // "pass" | "fail" | null
  final TrainingFeedback? feedback;

  const TrainingConversationPreview({
    required this.conversationId,
    required this.submodeId,
    this.difficultyLevel,
    required this.createdAt,
    this.attemptId,
    this.status,
    this.feedback,
  });

  bool get isEvaluated => status != null;
  bool get isPassed => status == 'pass';

  String get trainingTitle {
    try {
      return kTrainings.firstWhere((t) => t.submodeId == submodeId).title;
    } catch (_) {
      return submodeId;
    }
  }

  factory TrainingConversationPreview.fromJson(Map<String, dynamic> json) {
    final feedbackJson = json['feedback'] as Map<String, dynamic>?;
    return TrainingConversationPreview(
      conversationId: json['conversation_id'] as String,
      submodeId: json['submode_id'] as String,
      difficultyLevel: json['difficulty_level'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      attemptId: json['attempt_id'] as String?,
      status: json['status'] as String?,
      feedback: feedbackJson != null ? TrainingFeedback.fromJson(feedbackJson) : null,
    );
  }
}

class TrainingFeedback {
  final List<String> observed;
  final List<String> interpretation;

  const TrainingFeedback({
    required this.observed,
    required this.interpretation,
  });

  factory TrainingFeedback.fromJson(Map<String, dynamic> json) {
    return TrainingFeedback(
      observed: List<String>.from(json['observed'] as List? ?? []),
      interpretation: List<String>.from(json['interpretation'] as List? ?? []),
    );
  }
}
