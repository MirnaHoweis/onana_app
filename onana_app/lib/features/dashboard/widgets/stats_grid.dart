import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dashboard_stats.dart';
import 'stat_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          label: 'Active Projects',
          value: stats.activeProjects.toString(),
          icon: Icons.apartment_outlined,
          color: AppColors.softGold,
        ),
        StatCard(
          label: 'Pending Requests',
          value: stats.pendingRequests.toString(),
          icon: Icons.assignment_outlined,
          color: AppColors.warningAmber,
        ),
        StatCard(
          label: 'Overdue Items',
          value: stats.overdueItems.toString(),
          icon: Icons.schedule_outlined,
          color: AppColors.errorRed,
        ),
        StatCard(
          label: 'Installing',
          value: stats.installationsInProgress.toString(),
          icon: Icons.build_outlined,
          color: AppColors.successGreen,
        ),
      ],
    );
  }
}
