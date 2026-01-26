import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/dc_scaffold.dart';
import '../../shared/widgets/mode_list_item.dart';

/// Экран выбора режима для Dating Coach
/// 
/// "What do you want to focus on right now?"
/// - Open Chat
/// - Practice
/// - Understanding
/// - Guided Reflection
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DCScaffold(
      showMenu: true,
      onMenuTap: () {
        // TODO: Open menu/drawer
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          // Title with accent word
          _buildTitle(),
          
          const SizedBox(height: 80),
          
          // Mode list
          _buildModeList(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text.rich(
      TextSpan(
        style: AppTypography.titleLarge,
        children: [
          const TextSpan(text: 'What do you want to '),
          TextSpan(
            text: 'focus',
            style: AppTypography.titleLargeAccent,
          ),
          const TextSpan(text: ' on right now?'),
        ],
      ),
    );
  }

  Widget _buildModeList() {
    return Column(
      children: [
        ModeListItem(
          title: 'Open Chat',
          subtitle: 'Unstructured space for thoughts and words.',
          onTap: () {
            // TODO: Navigate to Open Chat
          },
        ),
        const SizedBox(height: 36),
        
        ModeListItem(
          title: 'Practice',
          subtitle: 'Situations that unfold step by step.',
          onTap: () {
            // TODO: Navigate to Practice
          },
        ),
        const SizedBox(height: 36),
        
        ModeListItem(
          title: 'Understanding',
          subtitle: 'Looking at interactions and situations to understand what is going on.',
          onTap: () {
            // TODO: Navigate to Understanding
          },
        ),
        const SizedBox(height: 36),
        
        ModeListItem(
          title: 'Guided Reflection',
          subtitle: 'Structured prompts for focused reflection.',
          onTap: () {
            // TODO: Navigate to Guided Reflection
          },
        ),
      ],
    );
  }
}
