import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Элемент списка режимов для Dating Coach
/// 
/// Карточка с заголовком и описанием
/// При нажатии меняет цвет на primary
class ModeListItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool disabled;

  const ModeListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.disabled = false,
  });

  @override
  State<ModeListItem> createState() => _ModeListItemState();
}

class _ModeListItemState extends State<ModeListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.onTap == null;

    return GestureDetector(
      onTap: isDisabled ? null : widget.onTap,
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isDisabled ? 0.35 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..translate(_isPressed ? 4.0 : 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.title,
                style: AppTypography.titleMedium.copyWith(
                  color: _isPressed
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                widget.subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: _isPressed
                      ? AppColors.textSecondary.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
