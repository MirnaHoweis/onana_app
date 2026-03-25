class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.createdAt,
    this.content,
    this.voiceUrl,
    this.projectId,
    this.unitId,
    this.requestId,
    this.projectName,
    this.unitName,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String? content;
  final String? voiceUrl;
  final String? projectId;
  final String? unitId;
  final String? requestId;
  // Denormalised for display
  final String? projectName;
  final String? unitName;

  bool get hasVoice => voiceUrl != null && voiceUrl!.isNotEmpty;
  bool get hasText => content != null && content!.isNotEmpty;

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String?,
      voiceUrl: json['voice_url'] as String?,
      projectId: json['project_id'] as String?,
      unitId: json['unit_id'] as String?,
      requestId: json['request_id'] as String?,
      projectName: json['project_name'] as String?,
      unitName: json['unit_name'] as String?,
    );
  }
}
