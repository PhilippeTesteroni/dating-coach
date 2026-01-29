import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Кнопка "назад" (стрелка влево)
/// 
/// Переиспользуемый компонент для навигации
class DCBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const DCBackButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(
          Icons.arrow_back,
          size: 24,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
