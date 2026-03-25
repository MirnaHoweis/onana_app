// ---------------------------------------------------------------------------
// Suggest Actions
// ---------------------------------------------------------------------------

class SuggestedAction {
  const SuggestedAction({
    required this.action,
    required this.reason,
    required this.priority,
  });

  final String action;
  final String reason;
  final String priority; // "high" | "medium" | "low"

  factory SuggestedAction.fromJson(Map<String, dynamic> json) {
    return SuggestedAction(
      action: json['action'] as String,
      reason: json['reason'] as String,
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

class SuggestActionsResult {
  const SuggestActionsResult({
    required this.requestId,
    required this.actions,
  });

  final String requestId;
  final List<SuggestedAction> actions;

  factory SuggestActionsResult.fromJson(Map<String, dynamic> json) {
    return SuggestActionsResult(
      requestId: json['request_id'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => SuggestedAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Detect Delays
// ---------------------------------------------------------------------------

class DelayAlert {
  const DelayAlert({
    required this.requestId,
    required this.title,
    required this.stage,
    required this.daysOverdue,
    required this.recommendation,
  });

  final String requestId;
  final String title;
  final String stage;
  final int daysOverdue;
  final String recommendation;

  factory DelayAlert.fromJson(Map<String, dynamic> json) {
    return DelayAlert(
      requestId: json['request_id'] as String,
      title: json['title'] as String,
      stage: json['stage'] as String,
      daysOverdue: json['days_overdue'] as int? ?? 0,
      recommendation: json['recommendation'] as String,
    );
  }
}

class DetectDelaysResult {
  const DetectDelaysResult({required this.alerts});
  final List<DelayAlert> alerts;

  factory DetectDelaysResult.fromJson(Map<String, dynamic> json) {
    return DetectDelaysResult(
      alerts: (json['alerts'] as List<dynamic>)
          .map((e) => DelayAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Summary
// ---------------------------------------------------------------------------

class DailySummary {
  const DailySummary({
    required this.summary,
    required this.highlights,
    required this.pendingCount,
    required this.overdueCount,
  });

  final String summary;
  final List<String> highlights;
  final int pendingCount;
  final int overdueCount;

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      summary: json['summary'] as String,
      highlights: (json['highlights'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      pendingCount: json['pending_count'] as int? ?? 0,
      overdueCount: json['overdue_count'] as int? ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Note to Task
// ---------------------------------------------------------------------------

class ExtractedTask {
  const ExtractedTask({
    required this.title,
    required this.description,
    required this.priority,
    this.dueHint,
  });

  final String title;
  final String description;
  final String priority;
  final String? dueHint;

  factory ExtractedTask.fromJson(Map<String, dynamic> json) {
    return ExtractedTask(
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      dueHint: json['due_hint'] as String?,
    );
  }
}

class NoteToTaskResult {
  const NoteToTaskResult({required this.tasks});
  final List<ExtractedTask> tasks;

  factory NoteToTaskResult.fromJson(Map<String, dynamic> json) {
    return NoteToTaskResult(
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => ExtractedTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat message (local UI model)
// ---------------------------------------------------------------------------

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final ChatRole role;
  final String text;
  final DateTime timestamp;
}
