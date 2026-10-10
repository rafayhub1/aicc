class AdminActivity {
  const AdminActivity({
    required this.id,
    required this.type,
    required this.registrationNumber,
    required this.read,
    this.timestamp,
  });

  final String id;
  final String type;
  final String registrationNumber;
  final bool read;
  final DateTime? timestamp;

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? 'other'}',
      registrationNumber: '${json['registrationNumber'] ?? ''}',
      read: json['read'] == true,
      timestamp: DateTime.tryParse('${json['timestamp']}'),
    );
  }
}
