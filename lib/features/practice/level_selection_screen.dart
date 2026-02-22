import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../data/models/training_meta.dart';
import '../../data/models/training_progress.dart';
import '../../services/characters_service.dart';
import '../../services/practice_service.dart';
import '../../services/user_service.dart';
import '../../shared/navigation/dc_page_route.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_credits_paywall.dart';
import '../../shared/widgets/dc_header.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import '../open_chat/chat_screen.dart';
import 'result_screen.dart';

const _levelLabels = ['Easy', 'Medium', 'Hard'];
const _levelSubtitles = [
  'A comfortable start.',
  'More realistic responses.',
  'High resistance, real pressure.',
];

/// Экран выбора уровня сложности тренировки.
/// При выборе уровня открывает выбор персонажа.
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

  void _onLevelTap(BuildContext context, int difficultyLevel) {
    Navigator.of(context).push(DCPageRoute(
      page: _CharacterPickerScreen(
        training: training,
        difficultyLevel: difficultyLevel,
        onLevelComplete: onLevelComplete,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DCHeader(
              title: 'Practice',
              leading: const DCBackButton(),
              trailing: DCMenuButton(
                onTap: () => showDCMenu(context, isSubscribed: UserService().isSubscribed),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(training.title, style: AppTypography.titleLarge),
                    const SizedBox(height: 48),
                    ...List.generate(3, (i) {
                      final level = i + 1;
                      final levelState = state.level(level);
                      final isUnlocked = levelState?.isUnlocked ?? false;
                      final isPassed = levelState?.passed ?? false;
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < 2 ? 36 : 0),
                        child: _LevelItem(
                          label: _levelLabels[i],
                          subtitle: _levelSubtitles[i],
                          isUnlocked: isUnlocked,
                          isPassed: isPassed,
                          onTap: isUnlocked
                              ? () => _onLevelTap(context, level)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _LevelItem ─────────────────────────────────────────────────────────────

class _LevelItem extends StatefulWidget {
  final String label;
  final String subtitle;
  final bool isUnlocked;
  final bool isPassed;
  final VoidCallback? onTap;

  const _LevelItem({
    required this.label,
    required this.subtitle,
    required this.isUnlocked,
    required this.isPassed,
    this.onTap,
  });

  @override
  State<_LevelItem> createState() => _LevelItemState();
}

class _LevelItemState extends State<_LevelItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = !widget.isUnlocked
        ? AppColors.textSecondary.withOpacity(0.35)
        : (_isPressed ? AppColors.primary : AppColors.textPrimary);
    final subtitleColor = !widget.isUnlocked
        ? AppColors.textSecondary.withOpacity(0.25)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..translate(_isPressed ? 4.0 : 0.0, 0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: AppTypography.titleMedium.copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(widget.subtitle, style: AppTypography.bodyMedium.copyWith(color: subtitleColor)),
                ],
              ),
            ),
            if (widget.isPassed) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _CharacterPickerScreen ─────────────────────────────────────────────────

class _CharacterPickerScreen extends StatefulWidget {
  final TrainingMeta training;
  final int difficultyLevel;
  final VoidCallback? onLevelComplete;

  const _CharacterPickerScreen({
    required this.training,
    required this.difficultyLevel,
    this.onLevelComplete,
  });

  @override
  State<_CharacterPickerScreen> createState() => _CharacterPickerScreenState();
}

class _CharacterPickerScreenState extends State<_CharacterPickerScreen> {
  List<Character> _characters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = UserService().profile;
      final preferredGender = profile?.preferredGender.name ?? 'all';
      final characters = await CharactersService().getCharacters(
        preferredGender: preferredGender,
      );
      // Precache thumbs
      if (mounted) {
        await Future.wait(
          characters.map((c) => precacheImage(
            CachedNetworkImageProvider(c.thumbUrl),
            context,
          )),
        );
      }
      if (mounted) setState(() { _characters = characters; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCharacterTap(Character character) async {
    // Check if free-tier user has enough messages for this level
    final userService = UserService();
    if (!userService.isSubscribed) {
      final remaining = userService.messagesRemaining ?? 0;
      int? messageLimit;
      try {
        messageLimit = await PracticeService().getMessageLimit(
          widget.training.submodeId,
          widget.difficultyLevel,
        );
      } catch (_) {}

      if (messageLimit != null && remaining < messageLimit) {
        if (!mounted) return;
        await DCCreditsPaywall.showForTraining(
          context,
          requiredMessages: messageLimit,
        );
        // Re-check after potential subscription
        if (!userService.isSubscribed) return;
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(DCPageRoute(
      page: ChatScreen(
        character: character,
        submodeId: widget.training.submodeId,
        difficultyLevel: widget.difficultyLevel,
        title: widget.training.title,
        onFinish: (conversationId) {
          // Replace ChatScreen with ResultScreen so back gesture
          // goes to CharacterPicker, not back to chat.
          Navigator.of(context).pushReplacement(DCPageRoute(
            page: ResultScreen(
              conversationId: conversationId,
              submodeId: widget.training.submodeId,
              difficultyLevel: widget.difficultyLevel,
              trainingTitle: widget.training.title,
              onDone: () {
                // pop result + pop character picker + pop level selection
                // → back to PracticeScreen (training list)
                Navigator.of(context).pop(); // result
                Navigator.of(context).pop(); // character picker
                Navigator.of(context).pop(); // level selection
                widget.onLevelComplete?.call();
              },
            ),
          ));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final levelLabel = _levelLabels[widget.difficultyLevel - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DCHeader(
              title: widget.training.title,
              leading: const DCBackButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Who are you talking to?',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      levelLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: _characters.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 24),
                          itemBuilder: (context, index) {
                            final character = _characters[index];
                            return _CharacterItem(
                              character: character,
                              onTap: () => _onCharacterTap(character),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _CharacterItem ─────────────────────────────────────────────────────────

class _CharacterItem extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const _CharacterItem({required this.character, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inputBackground,
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: character.thumbUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
              ),
              errorWidget: (_, __, ___) => Center(
                child: Text(character.name[0], style: AppTypography.titleMedium),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(character.name, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  character.description,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
