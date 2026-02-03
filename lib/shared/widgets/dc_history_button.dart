import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Текстовая кнопка "chats history"
/// 
/// Используется внизу экранов для перехода к истории чатов
class DCHistoryButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;

  const DCHistoryButton({
    super.key,
    this.onTap,
    this.text = 'chats history',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
