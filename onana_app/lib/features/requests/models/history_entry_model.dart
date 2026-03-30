class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.toStatus,
    required this.changedByName,
    required this.createdAt,
    this.fromStatus,
    this.notes,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String changedByName;
  final String? notes;
  final DateTime createdAt;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String,
      changedByName: json['changed_by_name'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
