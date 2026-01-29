import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Базовая модалка приложения с плавным появлением
class DCModal extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onClose;

  const DCModal({
    super.key,
    required this.title,
    required this.content,
    this.onClose,
  });

  /// Показать модалку с fade-анимацией
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return DCModal(
          title: title,
          content: content,
          onClose: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(title, style: AppTypography.titleMedium),
        if (onClose != null)
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
