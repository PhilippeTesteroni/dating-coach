import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Кнопка меню (бургер) для Dating Coach
/// 
/// Используется в правом верхнем углу экранов
class DCMenuButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  const DCMenuButton({
    super.key,
    this.onTap,
    this.size = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.menu,
          size: size,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}
