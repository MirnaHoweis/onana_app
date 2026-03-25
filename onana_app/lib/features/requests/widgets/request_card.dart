import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/request_model.dart';
import 'priority_badge.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: AppTypography.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PriorityBadge(priority: request.priority),
            ],
          ),
          if (request.unitName != null || request.projectName != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (request.projectName != null) request.projectName!,
                if (request.unitName != null) request.unitName!,
              ].join(' · '),
              style: AppTypography.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (request.supplierName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 12, color: AppColors.mutedBlueGray),
                const SizedBox(width: 4),
                Text(request.supplierName!, style: AppTypography.labelSmall),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              StatusBadge(stage: request.status),
              const Spacer(),
              if (request.expectedDeliveryDate != null)
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 12, color: AppColors.mutedBlueGray),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.expectedDeliveryDate!),
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';
}
