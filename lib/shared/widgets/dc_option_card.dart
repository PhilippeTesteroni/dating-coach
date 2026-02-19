import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Карточка выбора варианта
///
/// Выбранная — border primary, не выбранная — border обычный.
/// Переиспользуемая для любых списков выбора.
class DCOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const DCOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? AppTypography.semibold : AppTypography.regular,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AppTypography.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
