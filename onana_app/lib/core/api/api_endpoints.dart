class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Projects
  static const String projects = '/projects';
  static String project(String id) => '/projects/$id';

  // Units
  static String units(String projectId) => '/projects/$projectId/units';
  static String unit(String projectId, String unitId) =>
      '/projects/$projectId/units/$unitId';

  // Requests
  static const String requests = '/requests';
  static String request(String id) => '/requests/$id';
  static String requestHistory(String id) => '/requests/$id/history';

  // Installations
  static const String installations = '/installations';
  static String installation(String id) => '/installations/$id';

  // Notes
  static const String notes = '/notes';
  static String note(String id) => '/notes/$id';

  // Email
  static const String emailDrafts = '/email/drafts';
  static String emailDraft(String id) => '/email/drafts/$id';
  static String sendEmail(String id) => '/email/drafts/$id/send';

  // AI
  static const String aiSuggestActions = '/ai/suggest-actions';
  static const String aiDetectDelays = '/ai/detect-delays';
  static const String aiDailySummary = '/ai/daily-summary';
  static const String aiNoteToTask = '/ai/note-to-task';
}
