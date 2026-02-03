import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// Универсальный хедер экрана
///
/// Заголовок всегда по центру экрана независимо от ширины
/// leading/trailing виджетов.
class DCHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const DCHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title — always dead center
          Text(
            title,
            style: AppTypography.screenTitle,
            textAlign: TextAlign.center,
          ),
          // Leading + trailing via Row (vertically centered by default)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leading != null) leading! else const SizedBox.shrink(),
              if (trailing != null) trailing! else const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
