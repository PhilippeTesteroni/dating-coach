import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/dc_scaffold.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/mode_list_item.dart';
import '../../shared/navigation/dc_page_route.dart';
import '../../services/user_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../open_chat/character_selection_screen.dart';
import '../practice/practice_screen.dart';

/// Экран выбора режима для Dating Coach
/// 
/// "What do you want to focus on right now?"
/// - Open Chat
/// - Practice
/// - Understanding
/// - Guided Reflection
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _navigateWithOnboarding(BuildContext context, Widget destination) {
    if (!UserService().isProfileComplete) {
      Navigator.of(context).push(
        DCPageRoute(page: OnboardingScreen(destination: destination)),
      );
      return;
    }

    Navigator.of(context).push(
      DCPageRoute(page: destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DCScaffold(
      showMenu: true,
      onMenuTap: () {
        showDCMenu(context, isSubscribed: UserService().isSubscribed);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          // Title with accent word
          _buildTitle(),
          
          const SizedBox(height: 80),
          
          // Mode list
          _buildModeList(context),
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

  Widget _buildModeList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModeListItem(
          title: 'Open Chat',
          subtitle: 'Unstructured space for thoughts and words.',
          onTap: () => _navigateWithOnboarding(context, const CharacterSelectionScreen()),
        ),
        const SizedBox(height: 36),
        
        ModeListItem(
          title: 'Practice',
          subtitle: 'Situations that unfold step by step.',
          onTap: () => _navigateWithOnboarding(context, const PracticeScreen()),
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
