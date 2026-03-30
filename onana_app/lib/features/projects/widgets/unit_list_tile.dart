import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/unit_model.dart';

class UnitListTile extends StatelessWidget {
  const UnitListTile({
    super.key,
    required this.unit,
    required this.onTap,
    this.onDelete,
  });

  final UnitModel unit;
  final VoidCallback onTap;
  final Future<void> Function()? onDelete;

  static const Map<UnitType, IconData> _icons = {
    UnitType.villa: Icons.house_outlined,
    UnitType.apartment: Icons.apartment_outlined,
    UnitType.commercial: Icons.store_outlined,
  };

  static const Map<UnitType, String> _labels = {
    UnitType.villa: 'Villa',
    UnitType.apartment: 'Apartment',
    UnitType.commercial: 'Commercial',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 4),
              color: Color(0x0A000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sandBeige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _icons[unit.type]!,
                size: 18,
                color: AppColors.mutedBlueGray,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit.name, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    [
                      _labels[unit.type]!,
                      if (unit.floor != null) 'Floor ${unit.floor}',
                      if (unit.block != null) 'Block ${unit.block}',
                    ].join(' · '),
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (unit.currentStage != null)
                  StatusBadge(stage: unit.currentStage!),
                if (unit.activeRequestCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${unit.activeRequestCount} active',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.errorRed),
                tooltip: 'Delete unit',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _confirmDelete(context),
              )
            else
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.mutedBlueGray,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Delete "${unit.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete!();
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
