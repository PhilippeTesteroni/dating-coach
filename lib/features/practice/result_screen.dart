import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/training_meta.dart';
import '../../services/practice_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_header.dart';

/// Экран результата тренировки.
///
/// Вызывает evaluate при инициализации, показывает:
/// - pass/fail статус
/// - observed feedback (что делал пользователь)
/// - interpretation feedback (что это значит)
/// - разблокированные уровни (если есть)
///
/// Back (кнопка андроида / жест) → onDone (не на чат, а на LevelSelection).
class ResultScreen extends StatefulWidget {
  final String? conversationId;
  final String submodeId;
  final int difficultyLevel;
  final String trainingTitle;
  final VoidCallback onDone;
  /// Если передан — пропускает вызов evaluate и сразу показывает эти данные.
  /// Формат: { 'status': 'pass'|'fail', 'feedback': { 'observed': [...], 'interpretation': [...] } }
  final Map<String, dynamic>? initialResult;

  const ResultScreen({
    super.key,
    required this.conversationId,
    required this.submodeId,
    required this.difficultyLevel,
    required this.trainingTitle,
    required this.onDone,
    this.initialResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String? _error;

  String? _status;
  List<String> _observed = [];
  List<String> _interpretation = [];
  List<Map<String, dynamic>> _unlocked = [];

  @override
  void initState() {
    super.initState();
    // Если переданы готовые данные — не вызываем evaluate
    if (widget.initialResult != null) {
      final result = widget.initialResult!;
      final feedback = result['feedback'] as Map<String, dynamic>? ?? {};
      _status = result['status'] as String? ?? 'fail';
      _observed = List<String>.from(feedback['observed'] as List? ?? []);
      _interpretation = List<String>.from(feedback['interpretation'] as List? ?? []);
      _isLoading = false;
    } else {
      _evaluate();
    }
  }

  Future<void> _evaluate() async {
    if (widget.conversationId == null) {
      setState(() {
        _status = 'fail';
        _observed = ['You didn\'t send any messages.'];
        _interpretation = ['Start a conversation to get evaluated.'];
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await PracticeService().evaluate(
        conversationId: widget.conversationId!,
        submodeId: widget.submodeId,
        difficultyLevel: widget.difficultyLevel,
      );

      final feedback = result['feedback'] as Map<String, dynamic>? ?? {};

      setState(() {
        _status = result['status'] as String? ?? 'fail';
        _observed = List<String>.from(feedback['observed'] as List? ?? []);
        _interpretation = List<String>.from(feedback['interpretation'] as List? ?? []);
        _unlocked = List<Map<String, dynamic>>.from(result['unlocked'] as List? ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load your results. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDone();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              DCHeader(
                title: widget.trainingTitle,
                leading: DCBackButton(onTap: widget.onDone),
                trailing: GestureDetector(
                  onTap: widget.onDone,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Done',
                      style: AppTypography.buttonAccent.copyWith(color: AppColors.action),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoader()
                    : _error != null
                        ? _buildError()
                        : _buildResult(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              setState(() { _isLoading = true; _error = null; });
              _evaluate();
            },
            child: Text(
              'Try again',
              style: AppTypography.buttonAccent.copyWith(color: AppColors.action),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final isPassed = _status == 'pass';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Text(
            isPassed ? 'Well done.' : 'Not quite.',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed ? AppColors.textPrimary : Colors.transparent,
                  border: Border.all(color: AppColors.textPrimary, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPassed
                    ? 'You passed this level.'
                    : 'You didn\'t pass this time.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 48),

          if (_observed.isNotEmpty) ...[
            Text('What happened', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ..._observed.map((item) => _FeedbackItem(text: item)),
            const SizedBox(height: 36),
          ],

          if (_interpretation.isNotEmpty) ...[
            Text('What it means', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ..._interpretation.map((item) => _FeedbackItem(text: item)),
            const SizedBox(height: 36),
          ],

          if (_unlocked.isNotEmpty) ...[
            Text('Unlocked', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ..._unlocked.map((item) {
              final submodeId = item['submode_id'] as String? ?? '';
              final level = item['difficulty_level'] as int? ?? 1;
              final training = kTrainings.firstWhere(
                (t) => t.submodeId == submodeId,
                orElse: () => TrainingMeta(submodeId: submodeId, title: submodeId, subtitle: ''),
              );
              const levelLabels = ['Easy', 'Medium', 'Hard'];
              final levelLabel = levelLabels[(level - 1).clamp(0, 2)];
              return _FeedbackItem(text: '${training.title} · $levelLabel');
            }),
            const SizedBox(height: 36),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── _FeedbackItem ──────────────────────────────────────────────────────────

class _FeedbackItem extends StatelessWidget {
  final String text;

  const _FeedbackItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
