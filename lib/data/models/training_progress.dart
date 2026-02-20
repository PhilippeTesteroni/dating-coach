/// Состояние одного уровня тренировки
class TrainingLevelState {
  final int difficultyLevel; // 1=easy, 2=medium, 3=hard
  final bool isUnlocked;
  final bool passed;
  final String? passedAt;

  const TrainingLevelState({
    required this.difficultyLevel,
    required this.isUnlocked,
    required this.passed,
    this.passedAt,
  });

  factory TrainingLevelState.fromJson(Map<String, dynamic> json) {
    return TrainingLevelState(
      difficultyLevel: json['difficulty_level'] as int,
      isUnlocked: json['is_unlocked'] as bool,
      passed: json['passed'] as bool,
      passedAt: json['passed_at'] as String?,
    );
  }
}

/// Состояние одной тренировки (все 3 уровня)
class TrainingState {
  final String submodeId;
  final List<TrainingLevelState> levels;

  const TrainingState({
    required this.submodeId,
    required this.levels,
  });

  factory TrainingState.fromJson(Map<String, dynamic> json) {
    return TrainingState(
      submodeId: json['submode_id'] as String,
      levels: (json['levels'] as List)
          .map((l) => TrainingLevelState.fromJson(l))
          .toList(),
    );
  }

  TrainingLevelState? level(int difficulty) =>
      levels.where((l) => l.difficultyLevel == difficulty).firstOrNull;

  bool get hasAnyUnlocked => levels.any((l) => l.isUnlocked);
}

/// Полный прогресс пользователя
class TrainingProgress {
  final bool onboardingComplete;
  final String? preTrainingConversationId;
  final List<TrainingState> trainings;

  const TrainingProgress({
    required this.onboardingComplete,
    this.preTrainingConversationId,
    required this.trainings,
  });

  factory TrainingProgress.fromJson(Map<String, dynamic> json) {
    return TrainingProgress(
      onboardingComplete: json['onboarding_complete'] as bool,
      preTrainingConversationId: json['pre_training_conversation_id'] as String?,
      trainings: (json['trainings'] as List)
          .map((t) => TrainingState.fromJson(t))
          .toList(),
    );
  }

  TrainingState? forSubmode(String submodeId) =>
      trainings.where((t) => t.submodeId == submodeId).firstOrNull;
}
