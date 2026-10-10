class AppAccount {
  const AppAccount({
    required this.exists,
    this.uid,
    this.created,
    this.lastSignIn,
  });

  final bool exists;
  final String? uid;
  final DateTime? created;
  final DateTime? lastSignIn;

  factory AppAccount.fromJson(Map<String, dynamic> json) {
    return AppAccount(
      exists: json['exists'] == true,
      uid: json['uid'] == null ? null : '${json['uid']}',
      created: DateTime.tryParse('${json['created']}'),
      lastSignIn: DateTime.tryParse('${json['lastSignIn']}'),
    );
  }
}
