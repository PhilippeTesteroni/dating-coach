import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Карточка плана подписки
class SubscriptionPlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final String? description;
  final bool isFeatured;
  final bool isLoading;
  final VoidCallback? onTap;

  const SubscriptionPlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.period,
    this.description,
    this.isFeatured = false,
    this.isLoading = false,
    this.onTap,
  });

  String get _periodLabel {
    switch (period) {
      case 'week':
        return '/ week';
      case 'month':
        return '/ month';
      case 'year':
        return '/ year';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isFeatured
              ? AppColors.action.withOpacity(0.25)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: isFeatured
              ? Border.all(color: AppColors.action.withOpacity(0.4), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description ?? 'Unlimited messages',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Text(
                '$price $_periodLabel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
