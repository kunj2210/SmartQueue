import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class QueueIndicatorWidget extends StatefulWidget {
  final int currentToken;
  final int userToken;
  final double size;

  const QueueIndicatorWidget({
    super.key,
    required this.currentToken,
    required this.userToken,
    this.size = 160,
  });

  @override
  State<QueueIndicatorWidget> createState() => _QueueIndicatorWidgetState();
}

class _QueueIndicatorWidgetState extends State<QueueIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  bool get isNext => widget.userToken == widget.currentToken + 1;
  bool get isCurrent => widget.userToken == widget.currentToken;

  Color get _color {
    if (isCurrent || isNext) return AppColors.queueNext;
    final ahead = widget.userToken - widget.currentToken;
    if (ahead <= 5) return AppColors.queueSoon;
    return AppColors.queueWaiting;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (isNext || isCurrent) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QueueIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isNext || isCurrent) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (isNext || isCurrent) ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _color.withOpacity(0.15),
              _color.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: _color, width: 3),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NOW SERVING',
              style: TextStyle(
                fontSize: widget.size * 0.085,
                color: _color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#${widget.currentToken}',
              style: TextStyle(
                fontSize: widget.size * 0.28,
                color: _color,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
