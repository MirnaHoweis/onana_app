import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';

class StageFilterTabs extends StatelessWidget {
  const StageFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  final PipelineStage? selected;
  final ValueChanged<PipelineStage?> onChanged;
  final Map<PipelineStage?, int> counts;

  static const _tabs = [
    (label: 'All', stage: null),
    (label: 'Request', stage: PipelineStage.materialRequest),
    (label: 'PO Ask', stage: PipelineStage.poRequested),
    (label: 'PO', stage: PipelineStage.poCreated),
    (label: 'Delivery', stage: PipelineStage.delivery),
    (label: 'Confirmed', stage: PipelineStage.storekeeperConfirmed),
    (label: 'Installing', stage: PipelineStage.installationInProgress),
    (label: 'Done', stage: PipelineStage.installationComplete),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _tabs.map((t) {
          final isActive = t.stage == selected;
          final count = counts[t.stage] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(t.stage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.softGold : AppColors.sandBeige,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      t.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isActive
                            ? AppColors.deepCharcoal
                            : AppColors.mutedBlueGray,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.deepCharcoal.withValues(alpha: 0.15)
                              : AppColors.mutedBlueGray.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: AppTypography.labelSmall.copyWith(
                            color: isActive
                                ? AppColors.deepCharcoal
                                : AppColors.mutedBlueGray,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
