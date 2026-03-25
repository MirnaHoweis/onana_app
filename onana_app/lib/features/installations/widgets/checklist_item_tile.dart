import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/installation_model.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  final InstallationItemModel item;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x08000000),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!item.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? AppColors.successGreen
                    : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.successGreen
                      : AppColors.divider,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.itemName,
              style: AppTypography.bodyMedium.copyWith(
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: item.isCompleted
                    ? AppColors.mutedBlueGray
                    : AppColors.deepCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
