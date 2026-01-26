import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dc_menu_button.dart';

/// Базовый Scaffold для всех экранов Dating Coach
/// 
/// Включает:
/// - Фон #F3E6DB
/// - SafeArea
/// - Стандартные padding (24px)
/// - Опциональная кнопка меню
class DCScaffold extends StatelessWidget {
  final Widget child;
  final bool showMenu;
  final VoidCallback? onMenuTap;
  final EdgeInsets? padding;

  const DCScaffold({
    super.key,
    required this.child,
    this.showMenu = false,
    this.onMenuTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu button row
              if (showMenu)
                Align(
                  alignment: Alignment.topRight,
                  child: DCMenuButton(onTap: onMenuTap),
                ),
              
              // Main content
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
