import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'models/installation_model.dart';

final installationsProvider =
    AsyncNotifierProvider<InstallationsNotifier, List<InstallationModel>>(
  InstallationsNotifier.new,
);

class InstallationsNotifier extends AsyncNotifier<List<InstallationModel>> {
  @override
  Future<List<InstallationModel>> build() => _fetch();

  Future<List<InstallationModel>> _fetch() async {
    final response =
        await ApiClient.instance.get<List<dynamic>>('/installations');
    final data = response.data ?? [];
    return data
        .map((e) => InstallationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// ── Single installation ────────────────────────────────────────────────────

final installationProvider =
    AsyncNotifierProviderFamily<InstallationNotifier, InstallationModel, String>(
  InstallationNotifier.new,
);

class InstallationNotifier
    extends FamilyAsyncNotifier<InstallationModel, String> {
  @override
  Future<InstallationModel> build(String arg) => _fetch(arg);

  Future<InstallationModel> _fetch(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>('/installations/$id');
    return InstallationModel.fromJson(response.data!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> toggleItem(String itemId, {required bool isCompleted}) async {
    await ApiClient.instance.patch<Map<String, dynamic>>(
      '/installations/$arg/items/$itemId',
      data: {'is_completed': isCompleted},
    );
    // Optimistically update item in local state
    state = state.whenData((inst) {
      final updatedItems = inst.items.map((item) {
        if (item.id != itemId) return item;
        return item.copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );
      }).toList();
      final completed = updatedItems.where((i) => i.isCompleted).length;
      final pct = updatedItems.isEmpty
          ? 0
          : (completed / updatedItems.length * 100).round();
      return InstallationModel(
        id: inst.id,
        requestId: inst.requestId,
        completionPercentage: pct,
        isPartial: inst.isPartial,
        items: updatedItems,
        startDate: inst.startDate,
        estimatedEndDate: inst.estimatedEndDate,
        actualEndDate: inst.actualEndDate,
        notes: inst.notes,
        requestTitle: inst.requestTitle,
        unitName: inst.unitName,
        projectName: inst.projectName,
      );
    });
  }

  Future<void> addItem(String itemName) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/installations/$arg/items',
      data: {'item_name': itemName, 'sort_order': 0},
    );
    await refresh();
  }
}
