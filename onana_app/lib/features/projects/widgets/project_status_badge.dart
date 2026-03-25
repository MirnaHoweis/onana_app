import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';

class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge({super.key, required this.status});

  final ProjectStatus status;

  static const Map<ProjectStatus, _BadgeStyle> _styles = {
    ProjectStatus.planning: _BadgeStyle(
      label: 'Planning',
      bg: Color(0x266B7C85),
      text: AppColors.mutedBlueGray,
    ),
    ProjectStatus.active: _BadgeStyle(
      label: 'Active',
      bg: Color(0x266BAE8E),
      text: AppColors.successGreen,
    ),
    ProjectStatus.onHold: _BadgeStyle(
      label: 'On Hold',
      bg: Color(0x26D4A843),
      text: AppColors.warningAmber,
    ),
    ProjectStatus.completed: _BadgeStyle(
      label: 'Completed',
      bg: Color(0x26C8A96A),
      text: AppColors.softGold,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: AppTypography.labelSmall.copyWith(color: style.text),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.bg,
    required this.text,
  });
  final String label;
  final Color bg;
  final Color text;
}
