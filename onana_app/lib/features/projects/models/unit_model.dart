import '../../../core/utils/enums.dart';

class UnitModel {
  const UnitModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    this.floor,
    this.block,
    this.notes,
    this.activeRequestCount = 0,
    this.currentStage,
  });

  final String id;
  final String projectId;
  final String name;
  final UnitType type;
  final String? floor;
  final String? block;
  final String? notes;
  final int activeRequestCount;
  final PipelineStage? currentStage;

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      type: _parseType(json['type'] as String?),
      floor: json['floor'] as String?,
      block: json['block'] as String?,
      notes: json['notes'] as String?,
      activeRequestCount: (json['active_request_count'] as int?) ?? 0,
      currentStage: json['current_stage'] != null
          ? _parseStage(json['current_stage'] as String)
          : null,
    );
  }

  static UnitType _parseType(String? value) {
    switch (value) {
      case 'APARTMENT':
        return UnitType.apartment;
      case 'COMMERCIAL':
        return UnitType.commercial;
      default:
        return UnitType.villa;
    }
  }

  static PipelineStage _parseStage(String value) {
    const map = {
      'MATERIAL_REQUEST': PipelineStage.materialRequest,
      'PO_REQUESTED': PipelineStage.poRequested,
      'PO_CREATED': PipelineStage.poCreated,
      'DELIVERY': PipelineStage.delivery,
      'STOREKEEPER_CONFIRMED': PipelineStage.storekeeperConfirmed,
      'INSTALLATION_IN_PROGRESS': PipelineStage.installationInProgress,
      'INSTALLATION_COMPLETE': PipelineStage.installationComplete,
    };
    return map[value] ?? PipelineStage.materialRequest;
  }
}
