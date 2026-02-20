import 'training_meta.dart';

/// Превью одной попытки тренировки для экрана истории
class TrainingAttemptPreview {
  final String attemptId;
  final String? conversationId;
  final String submodeId;
  final int difficultyLevel;
  final String status; // "pass" | "fail"
  final DateTime createdAt;
  final TrainingFeedback? feedback;

  const TrainingAttemptPreview({
    required this.attemptId,
    this.conversationId,
    required this.submodeId,
    required this.difficultyLevel,
    required this.status,
    required this.createdAt,
    this.feedback,
  });

  bool get isPassed => status == 'pass';

  /// Название тренировки из kTrainings по submodeId
  String get trainingTitle {
    try {
      return kTrainings.firstWhere((t) => t.submodeId == submodeId).title;
    } catch (_) {
      return submodeId;
    }
  }

  factory TrainingAttemptPreview.fromJson(Map<String, dynamic> json) {
    final feedbackJson = json['feedback'] as Map<String, dynamic>?;
    return TrainingAttemptPreview(
      attemptId: json['attempt_id'] as String,
      conversationId: json['conversation_id'] as String?,
      submodeId: json['submode_id'] as String,
      difficultyLevel: json['difficulty_level'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
