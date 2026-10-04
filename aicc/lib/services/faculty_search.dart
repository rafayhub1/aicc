import '../models/faculty.dart';

List<Faculty> filterFaculty(
  List<Faculty> all, {
  String query = '',
  String? department,
}) {
  final q = query.trim().toLowerCase();
  final tokens = q
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 1)
      .toList();
  return all.where((faculty) {
    if (department != null &&
        department.isNotEmpty &&
        faculty.department != department) {
      return false;
    }
    if (q.isEmpty) return true;
    final haystack = [
      faculty.fullName,
      faculty.designation,
      faculty.department,
      faculty.officeBuilding,
      faculty.officeRoom,
      faculty.currentStatus,
      ...faculty.subjects,
    ].join(' ').toLowerCase();
    if (haystack.contains(q)) return true;
    return tokens.isNotEmpty && tokens.every(haystack.contains);
  }).toList();
}
