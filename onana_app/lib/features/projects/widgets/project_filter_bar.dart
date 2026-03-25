import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';

class ProjectFilterBar extends StatelessWidget {
  const ProjectFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProjectStatus? selected;
  final ValueChanged<ProjectStatus?> onChanged;

  static const _filters = [
    (label: 'All', value: null),
    (label: 'Active', value: ProjectStatus.active),
    (label: 'Planning', value: ProjectStatus.planning),
    (label: 'On Hold', value: ProjectStatus.onHold),
    (label: 'Completed', value: ProjectStatus.completed),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _filters.map((f) {
          final isActive = f.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.softGold : AppColors.sandBeige,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isActive
                        ? AppColors.deepCharcoal
                        : AppColors.mutedBlueGray,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
