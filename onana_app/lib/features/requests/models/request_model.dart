import '../../../core/utils/enums.dart';

class RequestModel {
  const RequestModel({
    required this.id,
    required this.unitId,
    required this.title,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.description,
    this.supplierName,
    this.poNumber,
    this.poDate,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    this.assignedTo,
    this.createdBy,
    this.projectName,
    this.unitName,
  });

  final String id;
  final String unitId;
  final String title;
  final RequestCategory category;
  final PipelineStage status;
  final RequestPriority priority;
  final DateTime createdAt;
  final String? description;
  final String? supplierName;
  final String? poNumber;
  final DateTime? poDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? assignedTo;
  final String? createdBy;
  // Denormalised for display
  final String? projectName;
  final String? unitName;

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      title: json['title'] as String,
      category: _parseCategory(json['category'] as String?),
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      supplierName: json['supplier_name'] as String?,
      poNumber: json['po_number'] as String?,
      poDate: json['po_date'] != null
          ? DateTime.tryParse(json['po_date'] as String)
          : null,
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.tryParse(json['expected_delivery_date'] as String)
          : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.tryParse(json['actual_delivery_date'] as String)
          : null,
      assignedTo: json['assigned_to'] as String?,
      createdBy: json['created_by'] as String?,
      projectName: json['project_name'] as String?,
      unitName: json['unit_name'] as String?,
    );
  }

  RequestModel copyWith({PipelineStage? status}) {
    return RequestModel(
      id: id,
      unitId: unitId,
      title: title,
      category: category,
      status: status ?? this.status,
      priority: priority,
      createdAt: createdAt,
      description: description,
      supplierName: supplierName,
      poNumber: poNumber,
      poDate: poDate,
      expectedDeliveryDate: expectedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate,
      assignedTo: assignedTo,
      createdBy: createdBy,
      projectName: projectName,
      unitName: unitName,
    );
  }

  static RequestCategory _parseCategory(String? v) {
    switch (v) {
      case 'APPLIANCE':
        return RequestCategory.appliance;
      case 'FINISHING':
        return RequestCategory.finishing;
      case 'OTHER':
        return RequestCategory.other;
      default:
        return RequestCategory.furniture;
    }
  }

  static PipelineStage _parseStatus(String? v) {
    const map = {
      'MATERIAL_REQUEST': PipelineStage.materialRequest,
      'PO_REQUESTED': PipelineStage.poRequested,
      'PO_CREATED': PipelineStage.poCreated,
      'DELIVERY': PipelineStage.delivery,
      'STOREKEEPER_CONFIRMED': PipelineStage.storekeeperConfirmed,
      'INSTALLATION_IN_PROGRESS': PipelineStage.installationInProgress,
      'INSTALLATION_COMPLETE': PipelineStage.installationComplete,
    };
    return map[v] ?? PipelineStage.materialRequest;
  }

  static RequestPriority _parsePriority(String? v) {
    switch (v) {
      case 'HIGH':
        return RequestPriority.high;
      case 'URGENT':
        return RequestPriority.urgent;
      case 'LOW':
        return RequestPriority.low;
      default:
        return RequestPriority.medium;
    }
  }
}
