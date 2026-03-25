import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/models/dashboard_stats.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepCharcoal),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined,
                color: AppColors.mutedBlueGray),
            onPressed: () =>
                ref.read(dashboardStatsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(
          child: Text('Could not load notifications',
              style: AppTypography.bodyMedium),
        ),
        data: (stats) {
          final hasAlerts = stats.delayAlerts.isNotEmpty;
          final hasPending = stats.pendingActions.isNotEmpty;

          if (!hasAlerts && !hasPending) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'All clear',
              subtitle: 'No pending actions or delay alerts right now.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (hasAlerts) ...[
                _SectionHeader(
                  icon: Icons.warning_amber_outlined,
                  label: 'Delay Alerts',
                  count: stats.delayAlerts.length,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 8),
                ...stats.delayAlerts
                    .map((a) => _DelayAlertTile(alert: a)),
                const SizedBox(height: 20),
              ],
              if (hasPending) ...[
                _SectionHeader(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending Actions',
                  count: stats.pendingActions.length,
                  color: AppColors.warningAmber,
                ),
                const SizedBox(height: 8),
                ...stats.pendingActions
                    .map((a) => _PendingActionTile(action: a)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _DelayAlertTile extends StatelessWidget {
  const _DelayAlertTile({required this.alert});
  final DelayAlert alert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${alert.daysLate}d late',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.errorRed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${alert.projectName} · ${alert.stage.replaceAll('_', ' ')}',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.mutedBlueGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingActionTile extends StatelessWidget {
  const _PendingActionTile({required this.action});
  final PendingAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: AppColors.warningAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle.isEmpty
                        ? action.projectName
                        : '${action.projectName} · ${action.subtitle}',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.mutedBlueGray),
                  ),
                  if (action.daysOverdue > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${action.daysOverdue}d overdue',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.errorRed),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
