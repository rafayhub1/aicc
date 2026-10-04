import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.read,
  });

  final String id;
  final String userId;
  final String type;
  final DateTime timestamp;
  final bool read;

  factory ActivityEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawTime = data['timestamp'];
    return ActivityEvent(
      id: doc.id,
      userId: '${data['user_id'] ?? ''}',
      type: '${data['type'] ?? 'other'}',
      timestamp: rawTime is Timestamp
          ? rawTime.toDate()
          : DateTime.tryParse('$rawTime') ?? DateTime.now(),
      read: data['read'] == true,
    );
  }
}
