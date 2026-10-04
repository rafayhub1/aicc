class InboxItem {
  const InboxItem({
    required this.id,
    required this.source,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
    this.documentUrl,
    this.documentTitle,
  });

  final String id;
  final String source;
  final String type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final String? documentUrl;
  final String? documentTitle;

  bool get isDocument => documentUrl != null;

  InboxItem copyWith({bool? read}) {
    return InboxItem(
      id: id,
      source: source,
      type: type,
      title: title,
      body: body,
      time: time,
      read: read ?? this.read,
      documentUrl: documentUrl,
      documentTitle: documentTitle,
    );
  }
}
