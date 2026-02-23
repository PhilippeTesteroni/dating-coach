/// Метаданные одной тренировки (статические, не зависят от прогресса)
class TrainingMeta {
  final String submodeId;
  final String title;
  final String subtitle;

  const TrainingMeta({
    required this.submodeId,
    required this.title,
    required this.subtitle,
  });
}

const kTrainings = [
  TrainingMeta(
    submodeId: 'first_contact',
    title: 'First Contact',
    subtitle: 'Opening messages and first impression.',
  ),
  TrainingMeta(
    submodeId: 'keep_conversation',
    title: 'Keep the Conversation',
    subtitle: 'Maintaining interest and natural flow.',
  ),
  TrainingMeta(
    submodeId: 'losing_interest',
    title: 'Losing Interest',
    subtitle: 'Re-engaging when things go cold.',
  ),
  TrainingMeta(
    submodeId: 'rejections',
    title: 'Rejections & Objections',
    subtitle: 'Handling no gracefully and without pressure.',
  ),
  TrainingMeta(
    submodeId: 'ask_for_date',
    title: 'Ask for a Date',
    subtitle: 'Moving from chat to real life.',
  ),
  TrainingMeta(
    submodeId: 'intimacy_boundaries',
    title: 'Intimacy & Boundaries',
    subtitle: 'Navigating closeness and respecting limits.',
  ),
  TrainingMeta(
    submodeId: 'after_date',
    title: 'After the Date',
    subtitle: 'Follow-up and keeping momentum.',
  ),
];

const _levelLabels = ['Easy', 'Medium', 'Hard'];

/// Динамическая подсказка: что нужно сделать, чтобы разблокировать тренировку
String? trainingUnlockHint(TrainingMeta training) {
  final idx = kTrainings.indexWhere((t) => t.submodeId == training.submodeId);
  if (idx == 0) return 'Complete the intro chat to unlock.';
  if (idx > 0) {
    final prev = kTrainings[idx - 1];
    return 'Pass Medium in ${prev.title} to unlock.';
  }
  return null;
}

/// Динамическая подсказка: что нужно сделать, чтобы разблокировать уровень
String? levelUnlockHint(int difficultyLevel) {
  if (difficultyLevel == 1) return null; // easy — разблокирован вместе с тренировкой
  if (difficultyLevel == 2) return 'Pass ${_levelLabels[0]} to unlock.';
  if (difficultyLevel == 3) return 'Pass ${_levelLabels[1]} to unlock.';
  return null;
}
