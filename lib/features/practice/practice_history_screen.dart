import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/character.dart';
import '../../data/models/training_attempt_preview.dart';
import '../../services/characters_service.dart';
import '../../services/practice_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_confirm_modal.dart';
import '../../shared/widgets/dc_header.dart';
import '../../shared/widgets/dc_menu.dart';
import '../../shared/widgets/dc_menu_button.dart';
import '../open_chat/chat_screen.dart';
import 'result_screen.dart';

const _levelLabels = ['Easy', 'Medium', 'Hard'];

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  final _service = PracticeService();

  List<TrainingConversationPreview> _conversations = [];
  Character? _coach;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        CharactersService().getCoach(),
        _service.getHistory(),
      ]);

      final coach = results[0] as Character;
      final conversations = results[1] as List<TrainingConversationPreview>;

      if (mounted) {
        await precacheImage(CachedNetworkImageProvider(coach.thumbUrl), context);
      }

      setState(() {
        _coach = coach;
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _onTap(TrainingConversationPreview conv) {
    if (_coach == null) return;

    // Если уже оценён — показываем результат сразу
    if (conv.isEvaluated) {
      _openResult(conv);
      return;
    }

    // Иначе — открываем чат (продолжить или посмотреть незаконченный)
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        character: _coach!,
        submodeId: conv.submodeId,
        conversationId: conv.conversationId,
        difficultyLevel: conv.difficultyLevel,
        title: conv.trainingTitle,
        attemptPreview: TrainingAttemptPreview(
          attemptId: conv.attemptId ?? '',
          conversationId: conv.conversationId,
          submodeId: conv.submodeId,
          difficultyLevel: conv.difficultyLevel ?? 1,
          status: conv.status ?? '',
          createdAt: conv.createdAt,
          feedback: conv.feedback,
        ),
      ),
    ));
  }

  void _openResult(TrainingConversationPreview conv) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        conversationId: conv.conversationId,
        submodeId: conv.submodeId,
        difficultyLevel: conv.difficultyLevel ?? 1,
        trainingTitle: conv.trainingTitle,
        onDone: () => Navigator.of(context).pop(),
        initialResult: {
          'status': conv.status,
          'feedback': {
            'observed': conv.feedback?.observed ?? [],
            'interpretation': conv.feedback?.interpretation ?? [],
          },
        },
      ),
    ));
  }

  Future<bool> _confirmDelete(TrainingConversationPreview conv) async {
    try {
      final confirmed = await DCConfirmModal.show(
        context: context,
        title: 'Delete training?',
        message: 'This conversation will be permanently deleted.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
      );
      if (confirmed != true) return false;
      await _service.deleteConversation(conv.conversationId);
      setState(() {
        _conversations.removeWhere((c) => c.conversationId == conv.conversationId);
      });
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            DCHeader(
              title: 'Training History',
              leading: const DCBackButton(),
              trailing: DCMenuButton(
                onTap: () => showDCMenu(context, isSubscribed: UserService().isSubscribed),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Text('Failed to load history', style: AppTypography.bodyMedium));
    }
    if (_conversations.isEmpty) {
      return Center(child: Text('No training history yet', style: AppTypography.bodyMedium));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return Dismissible(
          key: ValueKey(conv.conversationId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(conv),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.black, size: 28),
          ),
          child: _ConversationCard(
            conv: conv,
            coach: _coach,
            onTap: () => _onTap(conv),
          ),
        );
      },
    );
  }
}

// ── _ConversationCard ──────────────────────────────────────────────────────

class _ConversationCard extends StatelessWidget {
  final TrainingConversationPreview conv;
  final Character? coach;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conv,
    required this.coach,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(child: _buildInfo()),
          const SizedBox(width: 12),
          _buildStatusDot(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: coach != null
          ? CachedNetworkImage(
              imageUrl: coach!.thumbUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Center(child: Text(coach?.name[0] ?? 'H', style: AppTypography.titleMedium));
  }

  Widget _buildInfo() {
    final levelLabel = (conv.difficultyLevel != null &&
            conv.difficultyLevel! >= 1 &&
            conv.difficultyLevel! <= 3)
        ? _levelLabels[conv.difficultyLevel! - 1]
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                conv.trainingTitle,
                style: AppTypography.titleMedium.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(conv.createdAt),
              style: AppTypography.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(levelLabel, style: AppTypography.bodySmall),
            if (!conv.isEvaluated) ...[
              const SizedBox(width: 8),
              Text(
                'In progress',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDot() {
    // Не оценён — серый, fail — пустой, pass — заполненный
    final color = !conv.isEvaluated
        ? AppColors.textSecondary
        : AppColors.textPrimary;
    final filled = conv.isPassed;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
