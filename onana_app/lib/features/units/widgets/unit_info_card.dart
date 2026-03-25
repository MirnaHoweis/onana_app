import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';
import '../../projects/models/unit_model.dart';

class UnitInfoCard extends StatelessWidget {
  const UnitInfoCard({super.key, required this.unit});

  final UnitModel unit;

  static const Map<UnitType, String> _typeLabels = {
    UnitType.villa: 'Villa',
    UnitType.apartment: 'Apartment',
    UnitType.commercial: 'Commercial',
  };

  static const Map<UnitType, IconData> _typeIcons = {
    UnitType.villa: Icons.house_outlined,
    UnitType.apartment: Icons.apartment_outlined,
    UnitType.commercial: Icons.store_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sandBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _typeIcons[unit.type]!,
                  size: 18,
                  color: AppColors.mutedBlueGray,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.name, style: AppTypography.headingMedium),
                    Text(
                      _typeLabels[unit.type]!,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (unit.floor != null || unit.block != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (unit.floor != null)
                  _InfoChip(label: 'Floor', value: unit.floor!),
                if (unit.floor != null && unit.block != null)
                  const SizedBox(width: 8),
                if (unit.block != null)
                  _InfoChip(label: 'Block', value: unit.block!),
              ],
            ),
          ],
          if (unit.notes != null) ...[
            const SizedBox(height: 12),
            Text(
              unit.notes!,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedBlueGray),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sandBeige,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: AppTypography.labelSmall,
            ),
            TextSpan(
              text: value,
              style: AppTypography.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
