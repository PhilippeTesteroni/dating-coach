import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../services/characters_service.dart';
import '../../services/user_service.dart';
import '../../shared/navigation/dc_page_route.dart';
import '../../shared/widgets/dc_header.dart';
import '../../shared/widgets/dc_help_button.dart';
import '../../shared/widgets/dc_history_button.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import '../../shared/widgets/dc_modal.dart';
import '../../shared/widgets/mode_list_item.dart';
import '../open_chat/chat_history_screen.dart';
import '../open_chat/chat_screen.dart';

/// Экран выбора подрежима Understanding (Разборы)
///
/// Четыре сабмода: dialog_analysis, situation_analysis,
/// behavior_analysis, self_reaction — все через тренера Хитча.
class UnderstandingScreen extends StatefulWidget {
  const UnderstandingScreen({super.key});

  @override
  State<UnderstandingScreen> createState() => _UnderstandingScreenState();
}

class _UnderstandingScreenState extends State<UnderstandingScreen> {
  static const _submodes = [
    _Submode(
      id: 'dialog_analysis',
      title: 'Dialogue Review',
      subtitle: 'A closer look at a conversation and its dynamics.',
    ),
    _Submode(
      id: 'situation_analysis',
      title: 'Situation Review',
      subtitle: 'Understanding the broader context of what is happening.',
    ),
    _Submode(
      id: 'behavior_analysis',
      title: "The Other Person's Behavior",
      subtitle: "Observing the other person's actions and signals.",
    ),
    _Submode(
      id: 'self_reaction',
      title: 'Your Own Reaction',
      subtitle: 'Looking at your responses, impulses, and decisions.',
    ),
  ];

  Character? _coach;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoach();
  }

  Future<void> _loadCoach() async {
    try {
      final coach = await CharactersService().getCoach();
      if (mounted) {
        setState(() {
          _coach = coach;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHelpModal() {
    DCModal.show(
      context: context,
      title: 'Understanding',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Understanding is a space to look more closely at something specific — a conversation, a situation, or a pattern of behavior.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'Four angles:',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Dialogue Review', style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semibold)),
            TextSpan(text: ' — breaking down a conversation you had: what happened, what worked, what didn\'t, and why.', style: AppTypography.bodyMedium),
          ])),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Situation Review', style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semibold)),
            TextSpan(text: ' — making sense of the broader context of what\'s going on.', style: AppTypography.bodyMedium),
          ])),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'The Other Person\'s Behavior', style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semibold)),
            TextSpan(text: ' — reading what someone\'s actions and signals actually mean.', style: AppTypography.bodyMedium),
          ])),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Your Own Reaction', style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semibold)),
            TextSpan(text: ' — examining why you responded a certain way and what it reveals.', style: AppTypography.bodyMedium),
          ])),
          const SizedBox(height: 16),
          Text(
            'The difference from Reflection: Understanding is about making sense of patterns. Reflection is about processing how something felt.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _onHistoryTap() {
    Navigator.of(context).push(
      DCPageRoute(
        page: const ChatHistoryScreen(
          submodeIds: [
            'dialog_analysis',
            'situation_analysis',
            'behavior_analysis',
            'self_reaction',
          ],
          title: 'Understanding',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 48),
                    Expanded(child: _buildContent()),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DCHeader(
      title: 'Understanding',
      leading: DCHelpButton(onTap: _showHelpModal),
      trailing: DCMenuButton(
        onTap: () => showDCMenu(context, isSubscribed: UserService().isSubscribed),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'What would you like to look at?',
      style: AppTypography.titleLarge,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_coach == null) {
      return Center(
        child: GestureDetector(
          onTap: () {
            setState(() => _isLoading = true);
            _loadCoach();
          },
          child: Text('Tap to retry', style: AppTypography.buttonAccent),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _submodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 36),
      itemBuilder: (context, index) {
        final submode = _submodes[index];
        return ModeListItem(
          title: submode.title,
          subtitle: submode.subtitle,
          onTap: () => _onSubmodeTap(submode),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Center(
      child: DCHistoryButton(onTap: _onHistoryTap),
    );
  }

  Future<void> _onSubmodeTap(_Submode submode) async {
    if (_coach == null) return;
    Navigator.of(context).push(DCPageRoute(
      page: ChatScreen(
        character: _coach!,
        submodeId: submode.id,
        title: 'Understanding',
      ),
    ));
  }
}

class _Submode {
  final String id;
  final String title;
  final String subtitle;

  const _Submode({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}
