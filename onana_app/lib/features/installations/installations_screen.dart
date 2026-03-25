import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import 'installations_providers.dart';
import 'models/installation_model.dart';
import 'widgets/completion_ring.dart';

class InstallationsScreen extends ConsumerWidget {
  const InstallationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instAsync = ref.watch(installationsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Installations',
                        style: AppTypography.headingMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    color: AppColors.mutedBlueGray,
                    onPressed: () => ref.invalidate(installationsProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: instAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingShimmer(itemCount: 5),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 48, color: AppColors.mutedBlueGray),
                      const SizedBox(height: 16),
                      Text('Could not load installations',
                          style: AppTypography.headingMedium),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(installationsProvider),
                        icon: const Icon(Icons.refresh,
                            color: AppColors.softGold),
                        label: Text('Retry',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.softGold)),
                      ),
                    ],
                  ),
                ),
                data: (installations) {
                  if (installations.isEmpty) {
                    return const EmptyState(
                      title: 'No installations yet',
                      subtitle:
                          'Installations appear here once a request reaches the installation stage.',
                      icon: Icons.build_outlined,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.softGold,
                    onRefresh: () =>
                        ref.read(installationsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: installations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => _InstallationCard(
                        installation: installations[i],
                        onTap: () => context
                            .go('/installations/${installations[i].id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallationCard extends StatelessWidget {
  const _InstallationCard({
    required this.installation,
    required this.onTap,
  });

  final InstallationModel installation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            CompletionRing(
              percentage: installation.completionPercentage,
              size: 56,
              strokeWidth: 5,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installation.requestTitle ?? 'Installation',
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (installation.unitName != null)
                    Text(
                      [
                        if (installation.projectName != null)
                          installation.projectName!,
                        installation.unitName!,
                      ].join(' · '),
                      style: AppTypography.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  _ProgressBar(
                      percentage: installation.completionPercentage),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${installation.completedItems}/${installation.items.length}',
              style: AppTypography.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percentage});
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: percentage / 100,
        minHeight: 4,
        backgroundColor: AppColors.sandBeige,
        valueColor: AlwaysStoppedAnimation<Color>(
          percentage == 100 ? AppColors.successGreen : AppColors.softGold,
        ),
      ),
    );
  }
}
