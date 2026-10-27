import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.actionLabel,
    this.actionUrl,
    this.placeIds = const [],
    this.source,
  });

  final String id;
  final String sessionId;
  final String userId;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? actionLabel;
  final String? actionUrl;
  final List<String> placeIds;
  final String? source;

  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'role': role,
      'content': content,
      'created_at': Timestamp.fromDate(createdAt),
      if (actionLabel != null) 'action_label': actionLabel,
      if (actionUrl != null) 'action_url': actionUrl,
      if (placeIds.isNotEmpty) 'place_ids': placeIds,
      if (source != null) 'answered_by': source,
    };
  }

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = data['created_at'];
    return ChatMessage(
      id: doc.id,
      sessionId: '${data['session_id'] ?? ''}',
      userId: '${data['user_id'] ?? ''}',
      role: '${data['role'] ?? 'assistant'}',
      content: '${data['content'] ?? ''}',
      createdAt: created is Timestamp
          ? created.toDate()
          : DateTime.tryParse('$created') ?? DateTime.now(),
      actionLabel: data['action_label'] == null ? null : '${data['action_label']}',
      actionUrl: data['action_url'] == null ? null : '${data['action_url']}',
      placeIds: data['place_ids'] is List
          ? [for (final id in data['place_ids'] as List) '$id']
          : const [],
      source: data['answered_by'] == null ? null : '${data['answered_by']}',
    );
  }
}
