import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final RequestPriority priority;

  static const Map<RequestPriority, _Style> _styles = {
    RequestPriority.low: _Style(
      label: 'Low',
      color: AppColors.mutedBlueGray,
    ),
    RequestPriority.medium: _Style(
      label: 'Medium',
      color: AppColors.warningAmber,
    ),
    RequestPriority.high: _Style(
      label: 'High',
      color: Color(0xFFE08040),
    ),
    RequestPriority.urgent: _Style(
      label: 'Urgent',
      color: AppColors.errorRed,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final s = _styles[priority]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: s.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: AppTypography.labelSmall.copyWith(color: s.color),
          ),
        ],
      ),
    );
  }
}

class _Style {
  const _Style({required this.label, required this.color});
  final String label;
  final Color color;
}
