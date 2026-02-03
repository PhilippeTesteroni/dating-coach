import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Круглая кнопка помощи с "?"
/// 
/// Используется для вызова информационных модалок
class DCHelpButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const DCHelpButton({
    super.key,
    this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textPrimary,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
