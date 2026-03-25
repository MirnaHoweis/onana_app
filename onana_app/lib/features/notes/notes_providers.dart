import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'models/note_model.dart';

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteModel>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<NoteModel>> {
  @override
  Future<List<NoteModel>> build() => _fetch();

  Future<List<NoteModel>> _fetch({String? projectId, String? unitId}) async {
    final params = <String, String>{
      if (projectId != null) 'project_id': projectId,
      if (unitId != null) 'unit_id': unitId,
    };
    final response = await ApiClient.instance.get<List<dynamic>>(
      '/notes',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data ?? [];
    return data
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create({
    required String title,
    String? content,
    String? voiceUrl,
    String? projectId,
    String? unitId,
    String? requestId,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/notes',
      data: {
        'title': title,
        if (content != null) 'content': content,
        if (voiceUrl != null) 'voice_url': voiceUrl,
        if (projectId != null) 'project_id': projectId,
        if (unitId != null) 'unit_id': unitId,
        if (requestId != null) 'request_id': requestId,
      },
    );
    await refresh();
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/notes/$id');
    state = state.whenData(
      (list) => list.where((n) => n.id != id).toList(),
    );
  }
}
