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
      final absolute = raw.startsWith('http://') || raw.startsWith('https://')
          ? raw
          : '$root/${raw.replaceFirst(RegExp(r'^/'), '')}';
      return _preferHttps(absolute, root);
    }
    final path = docType == 'roll_number_slip' ? 'roll-slip' : 'fee-challan';
    return '$root/students/$studentId/$path';
  }
}

String _preferHttps(String absolute, String root) {
  final uri = Uri.tryParse(absolute);
  final base = Uri.tryParse(root);
  if (uri == null || base == null) return absolute;
  if (uri.scheme == 'http' && uri.host == base.host) {
    return uri.replace(scheme: 'https').toString();
  }
  return absolute;
}
