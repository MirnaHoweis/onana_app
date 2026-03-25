import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'models/ai_models.dart';

// ---------------------------------------------------------------------------
// Daily Summary (auto-loaded)
// ---------------------------------------------------------------------------

final dailySummaryProvider = FutureProvider<DailySummary>((ref) async {
  final response =
      await ApiClient.instance.get<Map<String, dynamic>>('/ai/daily-summary');
  return DailySummary.fromJson(response.data as Map<String, dynamic>);
});

// ---------------------------------------------------------------------------
// Delay Detection
// ---------------------------------------------------------------------------

final delayAlertsProvider =
    AsyncNotifierProvider<DelayAlertsNotifier, DetectDelaysResult?>(
  DelayAlertsNotifier.new,
);

class DelayAlertsNotifier extends AsyncNotifier<DetectDelaysResult?> {
  @override
  Future<DetectDelaysResult?> build() async => null;

  Future<void> detect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ApiClient.instance
          .post<Map<String, dynamic>>('/ai/detect-delays', data: {});
      return DetectDelaysResult.fromJson(
          response.data as Map<String, dynamic>);
    });
  }
}

// ---------------------------------------------------------------------------
// Note-to-Task
// ---------------------------------------------------------------------------

final noteToTaskProvider =
    AsyncNotifierProvider<NoteToTaskNotifier, NoteToTaskResult?>(
  NoteToTaskNotifier.new,
);

class NoteToTaskNotifier extends AsyncNotifier<NoteToTaskResult?> {
  @override
  Future<NoteToTaskResult?> build() async => null;

  Future<void> convert(String noteText) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/ai/note-to-task',
        data: {'note_text': noteText},
      );
      return NoteToTaskResult.fromJson(
          response.data as Map<String, dynamic>);
    });
  }
}

// ---------------------------------------------------------------------------
// Chat (local state — messages sent as note-to-task or free-form context)
// ---------------------------------------------------------------------------

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void _add(ChatMessage msg) => state = [...state, msg];

  Future<void> send(String text) async {
    _add(ChatMessage(
      role: ChatRole.user,
      text: text,
      timestamp: DateTime.now(),
    ));

    // Use note-to-task endpoint as a general "extract insights" call
    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/ai/note-to-task',
        data: {'note_text': text},
      );
      final result = NoteToTaskResult.fromJson(
          response.data as Map<String, dynamic>);

      final reply = result.tasks.isEmpty
          ? 'No tasks found in your message.'
          : result.tasks
              .map((t) =>
                  '• **${t.title}** (${t.priority})\n  ${t.description}'
                  '${t.dueHint != null ? ' — ${t.dueHint}' : ''}')
              .join('\n\n');

      _add(ChatMessage(
        role: ChatRole.assistant,
        text: reply,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _add(ChatMessage(
        role: ChatRole.assistant,
        text: 'Sorry, I ran into an error: $e',
        timestamp: DateTime.now(),
      ));
    }
  }
}
