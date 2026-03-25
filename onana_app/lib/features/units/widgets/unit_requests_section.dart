import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/enums.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';

// Placeholder until Phase 4 wires up the requests provider.
// Shows empty state with correct structure so the screen compiles fully.
class UnitRequestsSection extends StatelessWidget {
  const UnitRequestsSection({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context) {
    // TODO(phase4): replace with real requests provider watch
    const List<_MockRequest> requests = [];

    if (requests.isEmpty) {
      return const EmptyState(
        title: 'No requests yet',
        subtitle: 'Tap "New" to create the first request for this unit.',
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _RequestTile(request: requests[i]),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final _MockRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.title, style: AppTypography.labelLarge),
                const SizedBox(height: 4),
                Text(request.category, style: AppTypography.labelSmall),
              ],
            ),
          ),
          StatusBadge(stage: request.stage),
        ],
      ),
    );
  }
}

class _MockRequest {
  const _MockRequest({
    required this.title,
    required this.category,
    required this.stage,
  });
  final String title;
  final String category;
  final PipelineStage stage;
}
