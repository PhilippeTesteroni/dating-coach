import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/training_meta.dart';
import '../../data/models/training_progress.dart';
import '../../services/practice_service.dart';
import '../../services/user_service.dart';
import '../../shared/navigation/dc_page_route.dart';
import '../../shared/widgets/dc_header.dart';
import '../../shared/widgets/dc_help_button.dart';
import '../../shared/widgets/dc_history_button.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import '../../shared/widgets/dc_modal.dart';
import 'level_selection_screen.dart';
import 'practice_history_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _practiceService = PracticeService();

  TrainingProgress? _progress;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final progress = await _practiceService.loadProgress();
      if (mounted) {
        setState(() {
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load. Tap to retry.';
          _isLoading = false;
        });
      }
    }
  }

  void _showHelpModal() {
    DCModal.show(
      context: context,
      title: 'Practice',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice is a structured space for working through situations over time.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'Each step unfolds gradually, allowing you to notice patterns and reactions as they appear.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'There is no right pace and no goal to complete everything.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'You can move forward when it feels relevant, or pause at any point.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _onTrainingTap(TrainingMeta training, TrainingState? state) {
    if (state == null || !state.hasAnyUnlocked) return;
    Navigator.of(context).push(DCPageRoute(
      page: LevelSelectionScreen(
        training: training,
        state: state,
        onLevelComplete: _load,
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
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DCHeader(
      title: 'Practice',
      leading: DCHelpButton(onTap: _showHelpModal),
      trailing: DCMenuButton(
        onTap: () => showDCMenu(context, isSubscribed: UserService().isSubscribed),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: _load,
          child: Text(_error!, style: AppTypography.buttonAccent),
        ),
      );
    }

    return _buildContent(_progress!);
  }

  Widget _buildContent(TrainingProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            style: AppTypography.titleLarge,
            children: [
              const TextSpan(text: 'What do you want to '),
              TextSpan(text: 'practice', style: AppTypography.titleLargeAccent),
              const TextSpan(text: ' today?'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: ListView.separated(
            itemCount: kTrainings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 36),
            itemBuilder: (context, index) {
              final training = kTrainings[index];
              final state = progress.forSubmode(training.submodeId);
              final isLocked = state == null || !state.hasAnyUnlocked;
              return _TrainingListItem(
                training: training,
                state: state,
                isLocked: isLocked,
                onTap: isLocked ? null : () => _onTrainingTap(training, state),
              );
            },
          ),
        ),

        Center(
          child: DCHistoryButton(
            onTap: () => Navigator.of(context).push(DCPageRoute(
              page: const PracticeHistoryScreen(),
            )),
          ),
        ),
      ],
    );
  }
}

// ── _TrainingListItem ──────────────────────────────────────────────────────

class _TrainingListItem extends StatefulWidget {
  final TrainingMeta training;
  final TrainingState? state;
  final bool isLocked;
  final VoidCallback? onTap;

  const _TrainingListItem({
    required this.training,
    required this.state,
    required this.isLocked,
    this.onTap,
  });

  @override
  State<_TrainingListItem> createState() => _TrainingListItemState();
}

class _TrainingListItemState extends State<_TrainingListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isLocked
        ? AppColors.textSecondary.withOpacity(0.35)
        : (_isPressed ? AppColors.primary : AppColors.textPrimary);
    final subtitleColor = widget.isLocked
        ? AppColors.textSecondary.withOpacity(0.25)
        : AppColors.textSecondary;

    final subtitleText = widget.isLocked
        ? (trainingUnlockHint(widget.training) ?? widget.training.subtitle)
        : widget.training.subtitle;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..translate(_isPressed ? 4.0 : 0.0, 0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.training.title,
                    style: AppTypography.titleMedium.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: AppTypography.bodyMedium.copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _LevelDots(state: widget.state, isLocked: widget.isLocked),
          ],
        ),
      ),
    );
  }
}

// ── _LevelDots ─────────────────────────────────────────────────────────────

class _LevelDots extends StatelessWidget {
  final TrainingState? state;
  final bool isLocked;

  const _LevelDots({required this.state, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: List.generate(3, (i) {
          final level = i + 1;
          final levelState = state?.level(level);
          final isPassed = levelState?.passed ?? false;
          final isUnlocked = levelState?.isUnlocked ?? false;

          Color dotColor;
          if (isLocked || !isUnlocked) {
            dotColor = AppColors.textSecondary.withOpacity(0.2);
          } else if (isPassed) {
            dotColor = AppColors.primary;
          } else {
            dotColor = AppColors.textSecondary.withOpacity(0.5);
          }

          return Padding(
            padding: EdgeInsets.only(left: i > 0 ? 5 : 0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          );
        }),
      ),
    );
  }
}
