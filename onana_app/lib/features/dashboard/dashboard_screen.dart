import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/section_header.dart';
import 'dashboard_providers.dart';
import 'widgets/delay_alert_tile.dart';
import 'widgets/pending_action_tile.dart';
import 'widgets/stats_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const _DashboardShimmer(),
          error: (e, _) => _DashboardError(
            onRetry: () => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) => RefreshIndicator(
            color: AppColors.softGold,
            onRefresh: () =>
                ref.read(dashboardStatsProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                _AppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: StatsGrid(stats: stats),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Pending Actions',
                      subtitle:
                          '${stats.pendingActions.length} items need attention',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: stats.pendingActions.isEmpty
                      ? const SliverToBoxAdapter(
                          child: EmptyState(
                            title: 'All caught up',
                            subtitle: 'No pending actions right now.',
                            icon: Icons.check_circle_outline,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => PendingActionTile(
                              action: stats.pendingActions[i],
                            ),
                            childCount: stats.pendingActions.length,
                          ),
                        ),
                ),
                if (stats.delayAlerts.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Delay Alerts',
                        subtitle: '${stats.delayAlerts.length} overdue',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DelayAlertTile(alert: stats.delayAlerts[i]),
                        ),
                        childCount: stats.delayAlerts.length,
                      ),
                    ),
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SliverAppBar(
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: AppTypography.labelSmall),
          Text('Dashboard', style: AppTypography.headingMedium),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.mutedBlueGray,
          onPressed: () => context.go('/notifications'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: LoadingShimmer(itemCount: 6),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_outlined,
            size: 48,
            color: AppColors.mutedBlueGray,
          ),
          const SizedBox(height: 16),
          Text('Could not load dashboard', style: AppTypography.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.mutedBlueGray),
          ),
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
