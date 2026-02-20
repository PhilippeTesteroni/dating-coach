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
