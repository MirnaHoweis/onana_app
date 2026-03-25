import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'models/email_draft_model.dart';

// ---------------------------------------------------------------------------
// List provider
// ---------------------------------------------------------------------------

final emailDraftsProvider =
    AsyncNotifierProvider<EmailDraftsNotifier, List<EmailDraftModel>>(
  EmailDraftsNotifier.new,
);

class EmailDraftsNotifier extends AsyncNotifier<List<EmailDraftModel>> {
  @override
  Future<List<EmailDraftModel>> build() => _fetch();

  Future<List<EmailDraftModel>> _fetch() async {
    final response =
        await ApiClient.instance.get<List<dynamic>>('/email/drafts');
    final data = response.data ?? [];
    return data
        .map((e) => EmailDraftModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<EmailDraftModel> create({
    required String subject,
    required String body,
    required String recipientType,
    String? recipientEmail,
    String? requestId,
  }) async {
    final response = await ApiClient.instance
        .post<Map<String, dynamic>>('/email/drafts', data: {
      'subject': subject,
      'body': body,
      'recipient_type': recipientType,
      if (recipientEmail != null) 'recipient_email': recipientEmail,
      if (requestId != null) 'request_id': requestId,
    });
    final draft =
        EmailDraftModel.fromJson(response.data as Map<String, dynamic>);
    state = state.whenData((list) => [draft, ...list]);
    return draft;
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/email/drafts/$id');
    state = state.whenData((list) => list.where((d) => d.id != id).toList());
  }

  Future<EmailDraftModel> sendDraft(String id, {String? toEmail}) async {
    final response = await ApiClient.instance
        .post<Map<String, dynamic>>('/email/drafts/$id/send', data: {
      if (toEmail != null) 'to_email': toEmail,
    });
    final updated =
        EmailDraftModel.fromJson(response.data as Map<String, dynamic>);
    state = state.whenData(
      (list) => list.map((d) => d.id == id ? updated : d).toList(),
    );
    return updated;
  }
}

// ---------------------------------------------------------------------------
// Single-draft provider (family)
// ---------------------------------------------------------------------------

final emailDraftProvider = FutureProvider.family<EmailDraftModel, String>(
  (ref, id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>('/email/drafts/$id');
    return EmailDraftModel.fromJson(response.data as Map<String, dynamic>);
  },
);
