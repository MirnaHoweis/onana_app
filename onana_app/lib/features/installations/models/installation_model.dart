class InstallationModel {
  const InstallationModel({
    required this.id,
    required this.requestId,
    required this.completionPercentage,
    required this.isPartial,
    required this.items,
    this.startDate,
    this.estimatedEndDate,
    this.actualEndDate,
    this.notes,
    this.requestTitle,
    this.unitName,
    this.projectName,
  });

  final String id;
  final String requestId;
  final int completionPercentage;
  final bool isPartial;
  final List<InstallationItemModel> items;
  final DateTime? startDate;
  final DateTime? estimatedEndDate;
  final DateTime? actualEndDate;
  final String? notes;
  // Denormalised for display
  final String? requestTitle;
  final String? unitName;
  final String? projectName;

  bool get isComplete => completionPercentage == 100;
  int get completedItems => items.where((i) => i.isCompleted).length;

  factory InstallationModel.fromJson(Map<String, dynamic> json) {
    return InstallationModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      completionPercentage: (json['completion_percentage'] as int?) ?? 0,
      isPartial: (json['is_partial'] as bool?) ?? false,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) =>
              InstallationItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      estimatedEndDate: json['estimated_end_date'] != null
          ? DateTime.tryParse(json['estimated_end_date'] as String)
          : null,
      actualEndDate: json['actual_end_date'] != null
          ? DateTime.tryParse(json['actual_end_date'] as String)
          : null,
      notes: json['notes'] as String?,
      requestTitle: json['request_title'] as String?,
      unitName: json['unit_name'] as String?,
      projectName: json['project_name'] as String?,
    );
  }
}

class InstallationItemModel {
  const InstallationItemModel({
    required this.id,
    required this.installationId,
    required this.itemName,
    required this.isCompleted,
    required this.sortOrder,
    this.completedAt,
    this.completedBy,
  });

  final String id;
  final String installationId;
  final String itemName;
  final bool isCompleted;
  final int sortOrder;
  final DateTime? completedAt;
  final String? completedBy;

  factory InstallationItemModel.fromJson(Map<String, dynamic> json) {
    return InstallationItemModel(
      id: json['id'] as String,
      installationId: json['installation_id'] as String,
      itemName: json['item_name'] as String,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      completedBy: json['completed_by'] as String?,
    );
  }

  InstallationItemModel copyWith({bool? isCompleted, DateTime? completedAt}) {
    return InstallationItemModel(
      id: id,
      installationId: installationId,
      itemName: itemName,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy,
    );
  }
}
