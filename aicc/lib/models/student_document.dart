class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.docType,
    required this.status,
    this.fileUrl,
  });

  final String id;
  final String docType;
  final String status;
  final String? fileUrl;

  bool get isReady => status == 'ready';

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['fileUrl'];
    return StudentDocument(
      id: '${json['id'] ?? ''}',
      docType: '${json['docType'] ?? ''}',
      status: '${json['status'] ?? 'pending'}',
      fileUrl: rawUrl == null || '$rawUrl'.trim().isEmpty ? null : '$rawUrl',
    );
  }

  String resolvedUrl(String baseUrl, String studentId) {
    final raw = fileUrl?.trim();
    final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
      return '$root/${raw.replaceFirst(RegExp(r'^/'), '')}';
    }
    final path = docType == 'roll_number_slip' ? 'roll-slip' : 'fee-challan';
    return '$root/students/$studentId/$path';
  }
}
