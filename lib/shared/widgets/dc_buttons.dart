import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Заполненная кнопка с персиковым фоном
class DCFilledButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const DCFilledButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.action.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : Text(
                  text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.semibold,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Главная текстовая кнопка (персиковая)
class DCPrimaryTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const DCPrimaryTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.action,
                  ),
                )
              : Text(
                  text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.action,
                    fontWeight: AppTypography.semibold,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Вторичная текстовая кнопка (чёрная)
class DCSecondaryTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const DCSecondaryTextButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.semibold,
            ),
          ),
        ),
      ),
    );
  }
}
