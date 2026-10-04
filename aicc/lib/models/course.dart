class Course {
  const Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.attendancePercent,
    required this.semester,
  });

  final String id;
  final String courseName;
  final String courseCode;
  final double attendancePercent;
  final int semester;

  factory Course.fromJson(Map<String, dynamic> json) {
    final percent = json['attendancePercent'];
    return Course(
      id: '${json['id'] ?? ''}',
      courseName: '${json['courseName'] ?? ''}',
      courseCode: '${json['courseCode'] ?? ''}',
      attendancePercent: percent is num
          ? percent.toDouble()
          : double.tryParse('$percent') ?? 0,
      semester: json['semester'] is num
          ? (json['semester'] as num).round()
          : int.tryParse('${json['semester']}') ?? 0,
    );
  }
}
