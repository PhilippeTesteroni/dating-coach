import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/training_meta.dart';
import '../../data/models/training_progress.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_scaffold.dart';

/// Экран выбора уровня сложности тренировки
/// TODO: реализовать в задаче 7
class LevelSelectionScreen extends StatelessWidget {
  final TrainingMeta training;
  final TrainingState state;
  final VoidCallback? onLevelComplete;

  const LevelSelectionScreen({
    super.key,
    required this.training,
    required this.state,
    this.onLevelComplete,
  });

  @override
  Widget build(BuildContext context) {
    return DCScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DCBackButton(),
          const SizedBox(height: 32),
          Text(training.title, style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Text('Level selection coming soon', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
