import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  factory ChatSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatSession(
      id: doc.id,
      userId: '${data['user_id'] ?? ''}',
      title: '${data['title'] ?? 'Chat'}',
      createdAt: _time(data['created_at']),
    );
  }
}

DateTime _time(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.now();
}
