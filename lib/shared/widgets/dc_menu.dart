import 'package:flutter/material.dart';
import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Боковое меню Dating Coach с анимацией
class DCMenu extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onAboutTap;
  final int? balance;

  const DCMenu({
    super.key,
    this.onClose,
    this.onProfileTap,
    this.onBalanceTap,
    this.onAboutTap,
    this.balance,
  });

  @override
  State<DCMenu> createState() => _DCMenuState();
}

class _DCMenuState extends State<DCMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Затемнение фона
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withOpacity(0.15),
              ),
            ),
          ),
          
          // Меню справа
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 280,
                color: AppColors.background,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Кнопка закрытия
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: _close,
                            child: const Icon(
                              Icons.close,
                              size: 28,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        _MenuItem(
                          title: 'Profile',
                          onTap: () async {
                            await _close();
                            widget.onProfileTap?.call();
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _MenuItem(
                          title: 'Balance',
                          trailing: widget.balance != null 
                              ? '${widget.balance} credits' 
                              : '— credits',
                          onTap: () async {
                            await _close();
                            widget.onBalanceTap?.call();
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _MenuItem(
                          title: 'About',
                          onTap: () async {
                            await _close();
                            widget.onAboutTap?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Text(title, style: AppTypography.titleMedium),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(
              trailing!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Показать меню как overlay
void showDCMenu(BuildContext context, {int? balance}) {
  final navigatorContext = context;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  
  entry = OverlayEntry(
    builder: (context) => DCMenu(
      balance: balance,
      onClose: () => entry.remove(),
      onProfileTap: () {
        Navigator.of(navigatorContext).pushNamed(Routes.profile);
      },
      onBalanceTap: () {
        Navigator.of(navigatorContext).pushNamed(Routes.balance);
      },
      onAboutTap: () {
        Navigator.of(navigatorContext).pushNamed(Routes.about);
      },
    ),
  );
  
  overlay.insert(entry);
}
