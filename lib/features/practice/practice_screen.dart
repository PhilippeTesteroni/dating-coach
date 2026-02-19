import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_scaffold.dart';

/// Заглушка Practice — пустой экран с заголовком
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DCScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DCBackButton(),
          const SizedBox(height: 32),
          Text('Practice', style: AppTypography.titleLarge),
        ],
      ),
    );
  }
}
