class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.read,
    required this.timestamp,
  });

  final String id;
  final String type;
  final String message;
  final bool read;
  final DateTime timestamp;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? 'other'}',
      message: '${json['message'] ?? ''}',
      read: json['read'] == true,
      timestamp: DateTime.tryParse('${json['timestamp']}') ?? DateTime.now(),
    );
  }
}
