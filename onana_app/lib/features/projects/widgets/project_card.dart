import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../models/project_model.dart';
import 'project_status_badge.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onDoubleTap,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ProjectStatusBadge(status: project.status),
            ],
          ),
          if (project.clientName != null) ...[
            const SizedBox(height: 4),
            Text(
              project.clientName!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedBlueGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (project.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.mutedBlueGray,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    project.location!,
                    style: AppTypography.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.apartment_outlined,
                size: 13,
                color: AppColors.mutedBlueGray,
              ),
              const SizedBox(width: 4),
              Text(
                '${project.unitCount} unit${project.unitCount == 1 ? '' : 's'}',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
