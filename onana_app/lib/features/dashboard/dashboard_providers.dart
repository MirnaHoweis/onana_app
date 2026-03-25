import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'models/dashboard_stats.dart';

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(
  DashboardStatsNotifier.new,
);

class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() => _fetch();

  Future<DashboardStats> _fetch() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>('/dashboard/stats');
    return DashboardStats.fromJson(response.data!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
