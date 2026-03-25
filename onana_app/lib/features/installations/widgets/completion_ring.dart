import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CompletionRing extends StatelessWidget {
  const CompletionRing({
    super.key,
    required this.percentage,
    this.size = 72,
    this.strokeWidth = 6,
  });

  final int percentage;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          percentage: percentage,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Text(
            '$percentage%',
            style: AppTypography.labelLarge.copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.percentage,
    required this.strokeWidth,
  });

  final int percentage;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.sandBeige
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (percentage > 0) {
      final sweepAngle = 2 * math.pi * (percentage / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = percentage == 100
              ? AppColors.successGreen
              : AppColors.softGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percentage != percentage;
}
