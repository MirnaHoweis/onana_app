import '../../../core/utils/enums.dart';

class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.status,
    this.location,
    this.clientName,
    this.startDate,
    this.endDate,
    this.unitCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final ProjectStatus status;
  final String? location;
  final String? clientName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int unitCount;
  final DateTime? createdAt;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: _parseStatus(json['status'] as String?),
      location: json['location'] as String?,
      clientName: json['client_name'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      unitCount: (json['unit_count'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static ProjectStatus _parseStatus(String? value) {
    switch (value) {
      case 'ACTIVE':
        return ProjectStatus.active;
      case 'ON_HOLD':
        return ProjectStatus.onHold;
      case 'COMPLETED':
        return ProjectStatus.completed;
      default:
        return ProjectStatus.planning;
    }
  }
}
