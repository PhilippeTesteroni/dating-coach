/// Информация о сценарии тренировки из S3
class ScenarioInfo {
  final String submodeId;
  final String? description;
  final List<ScenarioLevelInfo> difficultyLevels;

  const ScenarioInfo({
    required this.submodeId,
    this.description,
    required this.difficultyLevels,
  });

  factory ScenarioInfo.fromJson(Map<String, dynamic> json) {
    return ScenarioInfo(
      submodeId: json['submode_id'] as String,
      description: json['description'] as String?,
      difficultyLevels: (json['difficulty_levels'] as List? ?? [])
          .map((l) => ScenarioLevelInfo.fromJson(l))
          .toList(),
    );
  }

  int? messageLimit(int difficultyLevel) {
    for (final lv in difficultyLevels) {
      if (lv.level == difficultyLevel) return lv.messageLimit;
    }
    return null;
  }

  String? levelDescription(int difficultyLevel) {
    for (final lv in difficultyLevels) {
      if (lv.level == difficultyLevel) return lv.levelDescription;
    }
    return null;
  }
}

class ScenarioLevelInfo {
  final int level;
  final int messageLimit;
  final String? levelDescription;

  const ScenarioLevelInfo({
    required this.level,
    required this.messageLimit,
    this.levelDescription,
  });

  factory ScenarioLevelInfo.fromJson(Map<String, dynamic> json) {
    return ScenarioLevelInfo(
      level: json['level'] as int,
      messageLimit: (json['message_limit'] as int?) ?? 10,
      levelDescription: json['level_description'] as String?,
    );
  }
}
