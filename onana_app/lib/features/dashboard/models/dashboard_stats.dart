class DashboardStats {
  const DashboardStats({
    required this.totalProjects,
    required this.activeProjects,
    required this.pendingRequests,
    required this.overdueItems,
    required this.installationsInProgress,
    required this.pendingActions,
    required this.delayAlerts,
  });

  final int totalProjects;
  final int activeProjects;
  final int pendingRequests;
  final int overdueItems;
  final int installationsInProgress;
  final List<PendingAction> pendingActions;
  final List<DelayAlert> delayAlerts;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProjects: (json['total_projects'] as int?) ?? 0,
      activeProjects: (json['active_projects'] as int?) ?? 0,
      pendingRequests: (json['pending_requests'] as int?) ?? 0,
      overdueItems: (json['overdue_items'] as int?) ?? 0,
      installationsInProgress:
          (json['installations_in_progress'] as int?) ?? 0,
      pendingActions: (json['pending_actions'] as List<dynamic>? ?? [])
          .map((e) => PendingAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      delayAlerts: (json['delay_alerts'] as List<dynamic>? ?? [])
          .map((e) => DelayAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DashboardStats empty() => const DashboardStats(
        totalProjects: 0,
        activeProjects: 0,
        pendingRequests: 0,
        overdueItems: 0,
        installationsInProgress: 0,
        pendingActions: [],
        delayAlerts: [],
      );
}

class PendingAction {
  const PendingAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.projectName,
    required this.daysOverdue,
  });

  final String id;
  final String title;
  final String subtitle;
  final String projectName;
  final int daysOverdue;

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      daysOverdue: (json['days_overdue'] as int?) ?? 0,
    );
  }
}

class DelayAlert {
  const DelayAlert({
    required this.id,
    required this.title,
    required this.projectName,
    required this.daysLate,
    required this.stage,
  });

  final String id;
  final String title;
  final String projectName;
  final int daysLate;
  final String stage;

  factory DelayAlert.fromJson(Map<String, dynamic> json) {
    return DelayAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      projectName: json['project_name'] as String? ?? '',
      daysLate: (json['days_late'] as int?) ?? 0,
      stage: json['stage'] as String? ?? '',
    );
  }
}
