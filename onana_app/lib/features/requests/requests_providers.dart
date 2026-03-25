import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/enums.dart';
import 'models/request_model.dart';

// ── Requests list (optionally filtered by stage) ──────────────────────────

final requestsProvider =
    AsyncNotifierProvider<RequestsNotifier, List<RequestModel>>(
  RequestsNotifier.new,
);

class RequestsNotifier extends AsyncNotifier<List<RequestModel>> {
  @override
  Future<List<RequestModel>> build() => _fetch();

  Future<List<RequestModel>> _fetch({String? unitId, PipelineStage? stage}) async {
    final params = <String, String>{
      if (unitId != null) 'unit_id': unitId,
      if (stage != null) 'status': _stageToApi(stage),
    };
    final response = await ApiClient.instance.get<List<dynamic>>(
      '/requests',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data ?? [];
    return data
        .map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create({
    required String unitId,
    required String title,
    required RequestCategory category,
    required RequestPriority priority,
    String? description,
    String? supplierName,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/requests',
      data: {
        'unit_id': unitId,
        'title': title,
        'category': _categoryToApi(category),
        'priority': _priorityToApi(priority),
        if (description != null) 'description': description,
        if (supplierName != null) 'supplier_name': supplierName,
      },
    );
    await refresh();
  }

  Future<void> updateStatus(String id, PipelineStage stage, {String? notes}) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/requests/$id/status',
      data: {
        'status': _stageToApi(stage),
        if (notes != null) 'notes': notes,
      },
    );
    // Optimistically update the local list
    state = state.whenData(
      (list) => list.map((r) => r.id == id ? r.copyWith(status: stage) : r).toList(),
    );
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/requests/$id');
    state = state.whenData(
      (list) => list.where((r) => r.id != id).toList(),
    );
  }
}

// ── Single request ─────────────────────────────────────────────────────────

final requestProvider =
    AsyncNotifierProviderFamily<RequestNotifier, RequestModel, String>(
  RequestNotifier.new,
);

class RequestNotifier extends FamilyAsyncNotifier<RequestModel, String> {
  @override
  Future<RequestModel> build(String arg) => _fetch(arg);

  Future<RequestModel> _fetch(String id) async {
    final response =
        await ApiClient.instance.get<Map<String, dynamic>>('/requests/$id');
    return RequestModel.fromJson(response.data!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> updateStatus(PipelineStage stage, {String? notes}) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/requests/$arg/status',
      data: {
        'status': _stageToApi(stage),
        if (notes != null) 'notes': notes,
      },
    );
    await refresh();
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _stageToApi(PipelineStage s) {
  const map = {
    PipelineStage.materialRequest: 'MATERIAL_REQUEST',
    PipelineStage.poRequested: 'PO_REQUESTED',
    PipelineStage.poCreated: 'PO_CREATED',
    PipelineStage.delivery: 'DELIVERY',
    PipelineStage.storekeeperConfirmed: 'STOREKEEPER_CONFIRMED',
    PipelineStage.installationInProgress: 'INSTALLATION_IN_PROGRESS',
    PipelineStage.installationComplete: 'INSTALLATION_COMPLETE',
  };
  return map[s]!;
}

String _categoryToApi(RequestCategory c) {
  const map = {
    RequestCategory.furniture: 'FURNITURE',
    RequestCategory.appliance: 'APPLIANCE',
    RequestCategory.finishing: 'FINISHING',
    RequestCategory.other: 'OTHER',
  };
  return map[c]!;
}

String _priorityToApi(RequestPriority p) {
  const map = {
    RequestPriority.low: 'LOW',
    RequestPriority.medium: 'MEDIUM',
    RequestPriority.high: 'HIGH',
    RequestPriority.urgent: 'URGENT',
  };
  return map[p]!;
}
