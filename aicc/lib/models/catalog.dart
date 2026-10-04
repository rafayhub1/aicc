class Catalog {
  const Catalog({
    required this.departments,
    required this.semesters,
    required this.sections,
  });

  final List<String> departments;
  final List<int> semesters;
  final List<String> sections;

  factory Catalog.fromJson(Map<String, dynamic> json) {
    final rawDepartments = json['departments'];
    final departments = <String>[];
    if (rawDepartments is List) {
      for (final item in rawDepartments) {
        if (item is Map && item['code'] != null) {
          departments.add('${item['code']}');
        } else if (item != null) {
          departments.add('$item');
        }
      }
    }
    final semesters = <int>[];
    final rawSemesters = json['semesters'];
    if (rawSemesters is List) {
      for (final item in rawSemesters) {
        if (item is num) semesters.add(item.round());
      }
    }
    final sections = <String>[];
    final rawSections = json['sections'];
    if (rawSections is List) {
      for (final item in rawSections) {
        sections.add('$item');
      }
    }
    return Catalog(
      departments: departments,
      semesters: semesters,
      sections: sections,
    );
  }
}
