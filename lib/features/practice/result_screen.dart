import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
class ResultScreen extends StatefulWidget {
  final String? conversationId;
  final String submodeId;
  final int difficultyLevel;
  final String trainingTitle;
  final VoidCallback onDone;

  const ResultScreen({
    super.key,
    required this.conversationId,
    required this.submodeId,
    required this.difficultyLevel,
    required this.trainingTitle,
    required this.onDone,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String? _error;

  String? _status;             // "pass" | "fail"
  List<String> _observed = [];
  List<String> _interpretation = [];
  List<Map<String, dynamic>> _unlocked = [];

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    // Если conversationId нет — не было ни одного сообщения, сразу fail
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            DCHeader(
              title: widget.trainingTitle,
              leading: const DCBackButton(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: AppTypography.bodyMedium),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              setState(() { _isLoading = true; _error = null; });
              _evaluate();
            },
            child: Text(
              'Try again',
              style: AppTypography.buttonAccent.copyWith(color: AppColors.action),
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

          // ── Статус ──
          Text(
            isPassed ? 'Well done.' : 'Not quite.',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isPassed
                ? 'You passed this level.'
                : 'You didn\'t pass this time.',
            style: AppTypography.bodyMedium,
          ),

          const SizedBox(height: 48),

          // ── Observed ──
          if (_observed.isNotEmpty) ...[
            Text(
              'What happened',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._observed.map((item) => _FeedbackItem(text: item)),
            const SizedBox(height: 36),
          ],

          // ── Interpretation ──
          if (_interpretation.isNotEmpty) ...[
            Text(
              'What it means',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._interpretation.map((item) => _FeedbackItem(text: item)),
            const SizedBox(height: 36),
          ],

          // ── Unlocked ──
          if (_unlocked.isNotEmpty) ...[
            Text(
              'Unlocked',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'New levels are now available.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 36),
          ],

          // ── Done кнопка ──
          GestureDetector(
            onTap: widget.onDone,
            child: Text(
              'Done',
              style: AppTypography.buttonAccent.copyWith(color: AppColors.action),
            ),
          ),

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
