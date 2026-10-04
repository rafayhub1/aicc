import '../models/course.dart';

double? averageAttendance(List<Course> courses) {
  if (courses.isEmpty) return null;
  var sum = 0.0;
  for (final course in courses) {
    sum += course.attendancePercent;
  }
  return sum / courses.length;
}

List<Course> coursesForSemester(List<Course> courses, int semester) {
  return courses.where((course) => course.semester == semester).toList();
}
