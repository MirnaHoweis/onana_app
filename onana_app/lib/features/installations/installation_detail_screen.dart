import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/section_header.dart';
import 'installations_providers.dart';
import 'models/installation_model.dart';
import 'widgets/checklist_item_tile.dart';
import 'widgets/completion_ring.dart';

class InstallationDetailScreen extends ConsumerWidget {
  const InstallationDetailScreen({super.key, required this.installationId});

  final String installationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instAsync = ref.watch(installationProvider(installationId));

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: instAsync.when(
        loading: () => const _Shimmer(),
        error: (e, _) => _Error(
          onRetry: () =>
              ref.invalidate(installationProvider(installationId)),
        ),
        data: (inst) => CustomScrollView(
          slivers: [
            _AppBar(inst: inst),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SummaryCard(inst: inst),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Checklist',
                  subtitle:
                      '${inst.completedItems} / ${inst.items.length} done',
                  trailing: IconButton(
                    icon: const Icon(Icons.add, color: AppColors.softGold),
                    onPressed: () =>
                        _showAddItemSheet(context, ref, installationId),
                  ),
                ),
              ),
            ),
            inst.items.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No checklist items yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ChecklistItemTile(
                            item: inst.items[i],
                            onToggle: (v) => ref
                                .read(installationProvider(installationId)
                                    .notifier)
                                .toggleItem(inst.items[i].id,
                                    isCompleted: v),
                          ),
                        ),
                        childCount: inst.items.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showAddItemSheet(
      BuildContext context, WidgetRef ref, String id) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Checklist Item', style: AppTypography.headingMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Item name'),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  await ref
                      .read(installationProvider(id).notifier)
                      .addItem(name);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child:
                    Text('Add', style: AppTypography.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.inst});
  final InstallationModel inst;

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
      title: Text(
        inst.requestTitle ?? 'Installation',
        style: AppTypography.headingMedium,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.inst});
  final InstallationModel inst;

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
      child: Row(
        children: [
          CompletionRing(percentage: inst.completionPercentage),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${inst.completionPercentage}% complete',
                  style: AppTypography.headingMedium,
                ),
                const SizedBox(height: 4),
                if (inst.unitName != null)
                  Text(inst.unitName!, style: AppTypography.labelSmall),
                if (inst.projectName != null)
                  Text(inst.projectName!, style: AppTypography.labelSmall),
                const SizedBox(height: 8),
                if (inst.isPartial)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          AppColors.warningAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Partial',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingShimmer(itemCount: 5),
      );
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
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
          Text('Could not load installation',
              style: AppTypography.headingMedium),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.softGold),
            label: Text('Retry',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.softGold)),
          ),
        ],
      ),
    );
  }
}
