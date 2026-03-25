import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/pipeline_stepper.dart';
import '../../core/widgets/section_header.dart';
import '../projects/models/unit_model.dart';
import '../projects/projects_providers.dart';
import 'widgets/unit_info_card.dart';
import 'widgets/unit_requests_section.dart';

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({
    super.key,
    required this.projectId,
    required this.unitId,
  });

  final String projectId;
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(
      unitProvider((projectId: projectId, unitId: unitId)),
    );

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: unitAsync.when(
        loading: () => const _UnitShimmer(),
        error: (e, _) => _UnitError(
          onRetry: () => ref.invalidate(
            unitProvider((projectId: projectId, unitId: unitId)),
          ),
        ),
        data: (unit) => CustomScrollView(
          slivers: [
            _UnitAppBar(unit: unit),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: UnitInfoCard(unit: unit),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(title: 'Pipeline Stage'),
              ),
            ),
            SliverToBoxAdapter(
              child: _PipelineSection(unit: unit),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Requests',
                  trailing: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16,
                        color: AppColors.softGold),
                    label: Text(
                      'New',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.softGold),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverToBoxAdapter(
                child: UnitRequestsSection(unitId: unitId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitAppBar extends StatelessWidget {
  const _UnitAppBar({required this.unit});
  final UnitModel unit;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.deepCharcoal,
        onPressed: () => context.pop(),
      ),
      title: Text(unit.name, style: AppTypography.headingMedium),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.mutedBlueGray,
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _PipelineSection extends StatelessWidget {
  const _PipelineSection({required this.unit});
  final UnitModel unit;

  @override
  Widget build(BuildContext context) {
    final stage = unit.currentStage ?? PipelineStage.materialRequest;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: PipelineStepper(
        currentStage: stage,
        onStageTap: (tapped) {
          // Phase 4: show stage update bottom sheet
        },
      ),
    );
  }
}

class _UnitShimmer extends StatelessWidget {
  const _UnitShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: LoadingShimmer(itemCount: 5),
    );
  }
}

class _UnitError extends StatelessWidget {
  const _UnitError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.mutedBlueGray),
          const SizedBox(height: 16),
          Text('Could not load unit', style: AppTypography.headingMedium),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.softGold),
            label: Text(
              'Retry',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.softGold),
            ),
          ),
        ],
      ),
    );
  }
}
