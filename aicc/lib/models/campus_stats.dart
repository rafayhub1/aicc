class DepartmentCount {
  const DepartmentCount({
    required this.code,
    required this.name,
    required this.count,
  });

  final String code;
  final String name;
  final int count;
}

class CampusStats {
  const CampusStats({
    required this.totalStudents,
    required this.pendingDocuments,
    required this.byDepartment,
    this.averageCgpa,
    this.averageAttendance,
  });

  final int totalStudents;
  final int pendingDocuments;
  final List<DepartmentCount> byDepartment;
  final double? averageCgpa;
  final double? averageAttendance;

  factory CampusStats.fromJson(Map<String, dynamic> json) {
    final departments = <DepartmentCount>[];
    final raw = json['byDepartment'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final count = item['count'];
        departments.add(
          DepartmentCount(
            code: '${item['code'] ?? ''}',
            name: '${item['name'] ?? item['code'] ?? ''}',
            count: count is num ? count.round() : int.tryParse('$count') ?? 0,
          ),
        );
      }
    }
    return CampusStats(
      totalStudents: _asInt(json['totalStudents']),
      pendingDocuments: _asInt(json['pendingDocuments']),
      averageCgpa: _asDouble(json['averageCgpa']),
      averageAttendance: _asDouble(json['averageAttendance']),
      byDepartment: departments,
    );
  }
}

int _asInt(Object? value) {
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
