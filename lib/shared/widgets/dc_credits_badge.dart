import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Бейдж с количеством кредитов
/// 
/// Отображает "12 credits" в правом верхнем углу экрана
class DCCreditsBadge extends StatelessWidget {
  final int credits;

  const DCCreditsBadge({
    super.key,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$credits credits',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
