import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/enums.dart';

class PipelineStepper extends StatelessWidget {
  const PipelineStepper({
    super.key,
    required this.currentStage,
    required this.onStageTap,
  });

  final PipelineStage currentStage;
  final void Function(PipelineStage stage) onStageTap;

  static const List<_StepData> _steps = [
    _StepData(PipelineStage.materialRequest, 'Request'),
    _StepData(PipelineStage.poRequested, 'PO Ask'),
    _StepData(PipelineStage.poCreated, 'PO'),
    _StepData(PipelineStage.delivery, 'Delivery'),
    _StepData(PipelineStage.storekeeperConfirmed, 'Confirm'),
    _StepData(PipelineStage.installationInProgress, 'Install'),
    _StepData(PipelineStage.installationComplete, 'Done'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = PipelineStage.values.indexOf(currentStage);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_steps.length, (i) {
          final step = _steps[i];
          final stageIndex = PipelineStage.values.indexOf(step.stage);
          final isCompleted = stageIndex < currentIndex;
          final isActive = stageIndex == currentIndex;
          return _StepItem(
            data: step,
            isCompleted: isCompleted,
            isActive: isActive,
            isLast: i == _steps.length - 1,
            onTap: () => onStageTap(step.stage),
          );
        }),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.data,
    required this.isCompleted,
    required this.isActive,
    required this.isLast,
    required this.onTap,
  });

  final _StepData data;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Circle(
                isCompleted: isCompleted,
                isActive: isActive,
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: AppTypography.labelSmall.copyWith(
                  color: isCompleted || isActive
                      ? AppColors.softGold
                      : AppColors.mutedBlueGray,
                ),
              ),
            ],
          ),
          if (!isLast)
            Container(
              width: 24,
              height: 1,
              margin: const EdgeInsets.only(bottom: 20),
              color: isCompleted ? AppColors.softGold : AppColors.divider,
            ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.isCompleted, required this.isActive});

  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.softGold,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: AppColors.deepCharcoal),
      );
    }
    if (isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.softGold, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.softGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
    );
  }
}

class _StepData {
  const _StepData(this.stage, this.label);
  final PipelineStage stage;
  final String label;
}
