import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onDelete,
  });

  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.hasVoice)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.softGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 14,
                      color: AppColors.softGold),
                ),
              Expanded(
                child: Text(
                  note.title,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.mutedBlueGray),
                ),
            ],
          ),
          if (note.hasText) ...[
            const SizedBox(height: 6),
            Text(
              note.content!,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.mutedBlueGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                DateFormat('MMM d, yyyy · HH:mm').format(note.createdAt),
                style: AppTypography.labelSmall,
              ),
              if (note.projectName != null || note.unitName != null) ...[
                const SizedBox(width: 8),
                const Text('·',
                    style: TextStyle(color: AppColors.mutedBlueGray)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if (note.projectName != null) note.projectName!,
                      if (note.unitName != null) note.unitName!,
                    ].join(' › '),
                    style: AppTypography.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
