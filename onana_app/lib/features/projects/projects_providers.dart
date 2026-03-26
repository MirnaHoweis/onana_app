import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/enums.dart';
import 'models/project_model.dart';
import 'models/unit_model.dart';

// ── Projects list ──────────────────────────────────────────────────────────

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<ProjectModel>>(
  ProjectsNotifier.new,
);

class ProjectsNotifier extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() => _fetch();

  Future<List<ProjectModel>> _fetch() async {
    final response =
        await ApiClient.instance.get<List<dynamic>>('/projects');
    final data = response.data ?? [];
    return data
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create({
    required String name,
    String? location,
    String? clientName,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/projects',
      data: {
        'name': name,
        if (location != null) 'location': location,
        if (clientName != null) 'client_name': clientName,
      },
    );
    await refresh();
  }

  Future<void> updateStatus(String id, ProjectStatus status) async {
    await ApiClient.instance.patch<Map<String, dynamic>>(
      '/projects/$id',
      data: {'status': status.name.toUpperCase()},
    );
    await refresh();
  }
}

// ── Single project ─────────────────────────────────────────────────────────

final projectProvider = AsyncNotifierProviderFamily<ProjectNotifier,
    ProjectModel, String>(ProjectNotifier.new);

class ProjectNotifier extends FamilyAsyncNotifier<ProjectModel, String> {
  @override
  Future<ProjectModel> build(String arg) => _fetch(arg);

  Future<ProjectModel> _fetch(String id) async {
    final response =
        await ApiClient.instance.get<Map<String, dynamic>>('/projects/$id');
    return ProjectModel.fromJson(response.data!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

// ── Units for a project ────────────────────────────────────────────────────

final unitsProvider =
    AsyncNotifierProviderFamily<UnitsNotifier, List<UnitModel>, String>(
  UnitsNotifier.new,
);

class UnitsNotifier extends FamilyAsyncNotifier<List<UnitModel>, String> {
  @override
  Future<List<UnitModel>> build(String arg) => _fetch(arg);

  Future<List<UnitModel>> _fetch(String projectId) async {
    final response = await ApiClient.instance
        .get<List<dynamic>>('/projects/$projectId/units');
    final data = response.data ?? [];
    return data
        .map((e) => UnitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

// ── Project dashboard ──────────────────────────────────────────────────────

final projectDashboardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await ApiClient.instance
      .get<Map<String, dynamic>>('/projects/$id/dashboard');
  return response.data!;
});

// ── Single unit ────────────────────────────────────────────────────────────

final unitProvider =
    AsyncNotifierProviderFamily<UnitNotifier, UnitModel, ({String projectId, String unitId})>(
  UnitNotifier.new,
);

class UnitNotifier
    extends FamilyAsyncNotifier<UnitModel, ({String projectId, String unitId})> {
  @override
  Future<UnitModel> build(({String projectId, String unitId}) arg) =>
      _fetch(arg);

  Future<UnitModel> _fetch(
      ({String projectId, String unitId}) ids) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '/projects/${ids.projectId}/units/${ids.unitId}',
    );
    return UnitModel.fromJson(response.data!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}
