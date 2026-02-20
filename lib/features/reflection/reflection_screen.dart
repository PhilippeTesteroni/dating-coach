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

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  static const _submodes = [
    _Submode(
      id: 'reflection_after_rejection',
      title: 'After Rejection',
      subtitle: 'A moment to look at what happened and what it brought up.',
    ),
    _Submode(
      id: 'reflection_after_difficult_conversation',
      title: 'After a Difficult Conversation',
      subtitle: 'Noticing the dynamics, without judging yourself or the other person.',
    ),
    _Submode(
      id: 'reflection_after_meeting',
      title: 'After a Meeting',
      subtitle: 'Reflecting on impressions, signals, and your own reactions.',
    ),
    _Submode(
      id: 'reflection_before_important_step',
      title: 'Before an Important Step',
      subtitle: "Slowing down to clarify what you're about to do and why.",
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
      title: 'Reflection',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reflection is a quiet space to pause and look at a moment in time.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You choose a point — before or after an event — and explore '
            'what you noticed, felt, or understood.',
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
            'reflection_after_rejection',
            'reflection_after_difficult_conversation',
            'reflection_after_meeting',
            'reflection_before_important_step',
          ],
          title: 'Guided Reflection',
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
      title: 'Guided Reflection',
      leading: DCHelpButton(onTap: _showHelpModal),
      trailing: DCMenuButton(
        onTap: () => showDCMenu(context, isSubscribed: UserService().isSubscribed),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'What would you like to reflect on?',
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
        title: 'Guided Reflection',
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
