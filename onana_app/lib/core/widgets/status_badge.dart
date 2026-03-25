import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.stage});

  final PipelineStage stage;

  static const Map<PipelineStage, _BadgeData> _data = {
    PipelineStage.materialRequest: _BadgeData(
      label: 'Material Request',
      bg: Color(0x266B7C85),
      text: AppColors.mutedBlueGray,
    ),
    PipelineStage.poRequested: _BadgeData(
      label: 'PO Requested',
      bg: Color(0x26D4A843),
      text: AppColors.warningAmber,
    ),
    PipelineStage.poCreated: _BadgeData(
      label: 'PO Created',
      bg: Color(0x26C8A96A),
      text: AppColors.softGold,
    ),
    PipelineStage.delivery: _BadgeData(
      label: 'Delivery',
      bg: Color(0x266BAE8E),
      text: AppColors.successGreen,
    ),
    PipelineStage.storekeeperConfirmed: _BadgeData(
      label: 'Confirmed',
      bg: Color(0x266BAE8E),
      text: AppColors.successGreen,
    ),
    PipelineStage.installationInProgress: _BadgeData(
      label: 'Installing',
      bg: Color(0x26D4A843),
      text: AppColors.warningAmber,
    ),
    PipelineStage.installationComplete: _BadgeData(
      label: 'Complete',
      bg: Color(0x266BAE8E),
      text: AppColors.successGreen,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final info = _data[stage]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info.label,
        style: AppTypography.labelSmall.copyWith(color: info.text),
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.label,
    required this.bg,
    required this.text,
  });

  final String label;
  final Color bg;
  final Color text;
}
