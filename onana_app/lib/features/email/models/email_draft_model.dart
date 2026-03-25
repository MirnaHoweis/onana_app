import '../../../core/utils/enums.dart';

class EmailDraftModel {
  const EmailDraftModel({
    required this.id,
    required this.subject,
    required this.body,
    required this.recipientType,
    required this.isSent,
    required this.createdAt,
    this.recipientEmail,
    this.requestId,
    this.sentAt,
  });

  final String id;
  final String subject;
  final String body;
  final RecipientType recipientType;
  final bool isSent;
  final DateTime createdAt;
  final String? recipientEmail;
  final String? requestId;
  final DateTime? sentAt;

  factory EmailDraftModel.fromJson(Map<String, dynamic> json) {
    return EmailDraftModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      recipientType: _parseRecipientType(json['recipient_type'] as String?),
      isSent: json['is_sent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      recipientEmail: json['recipient_email'] as String?,
      requestId: json['request_id'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : null,
    );
  }

  EmailDraftModel copyWith({bool? isSent, DateTime? sentAt}) {
    return EmailDraftModel(
      id: id,
      subject: subject,
      body: body,
      recipientType: recipientType,
      isSent: isSent ?? this.isSent,
      createdAt: createdAt,
      recipientEmail: recipientEmail,
      requestId: requestId,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  static RecipientType _parseRecipientType(String? v) {
    switch (v) {
      case 'ACCOUNTING':
        return RecipientType.accounting;
      case 'SUPPLIER':
        return RecipientType.supplier;
      case 'STOREKEEPER':
        return RecipientType.storekeeper;
      default:
        return RecipientType.accounting;
    }
  }

  String get recipientTypeLabel {
    switch (recipientType) {
      case RecipientType.accounting:
        return 'Accounting';
      case RecipientType.supplier:
        return 'Supplier';
      case RecipientType.storekeeper:
        return 'Storekeeper';
    }
  }
}
