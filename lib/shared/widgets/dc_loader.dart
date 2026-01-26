import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Кастомный loader для Dating Coach
/// 
/// Дуга с анимацией вращения (3 секунды на оборот)
class DCLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const DCLoader({
    super.key,
    this.size = 32,
    this.color,
    this.strokeWidth = 1.0,
  });

  @override
  State<DCLoader> createState() => _DCLoaderState();
}

class _DCLoaderState extends State<DCLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ArcPainter(
          color: widget.color ?? AppColors.textSecondary,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

/// Рисует дугу (arc) как в Figma макете
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Дуга ~200 градусов (как в Figma: stroke-dasharray="45 25")
    const startAngle = -math.pi / 2;
    const sweepAngle = math.pi * 1.3;
    
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth;
  }
}
