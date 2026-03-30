import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Wraps any card with left-swipe-to-delete.
/// [onDelete] is called when the swipe is confirmed.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.itemKey,
    required this.child,
    required this.onDelete,
    this.label = 'Move to Trash',
  });

  final Key itemKey;
  final Widget child;
  final Future<void> Function() onDelete;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white)),
        ]),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        return true;
      },
      child: child,
    );
  }
}
