class Student {
  const Student({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.department,
    required this.semester,
    required this.section,
    required this.cgpaOverall,
  });

  final String id;
  final String name;
  final String registrationNumber;
  final String department;
  final int semester;
  final String section;
  final double cgpaOverall;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: '${json['id'] ?? json['registrationNumber'] ?? ''}',
      name: '${json['name'] ?? ''}',
      registrationNumber: '${json['registrationNumber'] ?? json['id'] ?? ''}',
      department: '${json['department'] ?? ''}',
      semester: _asInt(json['semester']),
      section: '${json['section'] ?? ''}',
      cgpaOverall: _asDouble(json['cgpaOverall']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
