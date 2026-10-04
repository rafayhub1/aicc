import 'package:aicc/core/academics.dart';
import 'package:aicc/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attendance average uses the current semester courses only', () {
    const courses = [
      Course(
        id: '1',
        courseName: 'Programming',
        courseCode: 'CSC101',
        attendancePercent: 80,
        semester: 1,
      ),
      Course(
        id: '2',
        courseName: 'English',
        courseCode: 'ENG101',
        attendancePercent: 90,
        semester: 1,
      ),
      Course(
        id: '3',
        courseName: 'Old course',
        courseCode: 'OLD',
        attendancePercent: 10,
        semester: 2,
      ),
    ];

    final current = coursesForSemester(courses, 1);
    expect(averageAttendance(current), 85);
    expect(averageAttendance(const []), isNull);
  });
}
