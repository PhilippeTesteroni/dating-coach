import 'package:flutter/material.dart';

/// Плавный fade-переход между экранами
class DCPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DCPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}
