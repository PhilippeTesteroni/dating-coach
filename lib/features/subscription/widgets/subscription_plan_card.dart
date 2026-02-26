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
  final String? badge;
  final VoidCallback? onTap;

  const SubscriptionPlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.period,
    this.description,
    this.isFeatured = false,
    this.isLoading = false,
    this.badge,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            AnimatedContainer(
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
            if (isLoading)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.action,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
