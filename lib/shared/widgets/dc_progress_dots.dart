import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Индикатор прогресса из точек
///
/// Заполненные (≤ current) — чёрные, остальные — пустые с border.
/// Переиспользуемый для любых пошаговых флоу.
class DCProgressDots extends StatelessWidget {
  final int total;
  final int current; // 0-based

  const DCProgressDots({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final filled = i <= current;
        return Padding(
          padding: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.textPrimary : AppColors.transparent,
              border: Border.all(
                color: AppColors.textPrimary,
                width: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
