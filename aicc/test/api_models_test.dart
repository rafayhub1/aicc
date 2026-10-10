import 'package:aicc/models/app_notification.dart';
import 'package:aicc/models/catalog.dart';
import 'package:aicc/models/course.dart';
import 'package:aicc/models/student.dart';
import 'package:aicc/models/student_document.dart';
import 'package:aicc/services/api_exception.dart';
import 'package:aicc/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('student, course, notification, and document match the backend names', () {
    final student = Student.fromJson(const {
      'name': 'Ayesha Malik',
      'registrationNumber': 'FA26-BSCS-001',
      'department': 'BSCS',
      'semester': 1,
      'section': 'A',
      'cgpaOverall': 2.48,
      'id': 'FA26-BSCS-001',
    });
    expect(student.name, 'Ayesha Malik');
    expect(student.registrationNumber, 'FA26-BSCS-001');
    expect(student.cgpaOverall, 2.48);

    final course = Course.fromJson(const {
      'courseName': 'Programming Fundamentals',
      'courseCode': 'CSC101',
      'attendancePercent': 73.73,
      'semester': 1,
      'id': '1_CSC101',
    });
    expect(course.courseCode, 'CSC101');
    expect(course.attendancePercent, 73.73);

    final notification = AppNotification.fromJson(const {
      'id': 'notif_1',
      'type': 'fee_challan_ready',
      'message': 'Your fee challan for the current semester is ready.',
      'timestamp': '2026-09-21T09:00:00+00:00',
      'read': true,
    });
    expect(notification.type, 'fee_challan_ready');
    expect(notification.read, isTrue);
    expect(notification.timestamp.toUtc().year, 2026);

    final document = StudentDocument.fromJson(const {
      'docType': 'fee_challan',
      'status': 'pending',
      'fileUrl': null,
      'id': 'fee_challan',
    });
    expect(document.docType, 'fee_challan');
    expect(document.fileUrl, isNull);
    expect(document.isReady, isFalse);
  });

  test('catalog reads department codes from the backend objects', () {
    final catalog = Catalog.fromJson(const {
      'departments': [
        {'code': 'BSCS', 'name': 'BS Computer Science'},
      ],
      'semesters': [1, 2, 3, 4],
      'sections': ['A', 'B'],
    });
    expect(catalog.departments, ['BSCS']);
    expect(catalog.semesters, [1, 2, 3, 4]);
    expect(catalog.sections, ['A', 'B']);
  });

  test('a missing student is NotFound and a timeout is ServerAsleep after one retry', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final missing = ApiService(
      prefs,
      client: MockClient((request) async {
        return http.Response('{"detail":"Student not found"}', 404);
      }),
    );
    await expectLater(
      missing.getStudent('NOPE-XXXX-000'),
      throwsA(isA<ApiNotFound>()),
    );

    var calls = 0;
    final asleep = ApiService(
      prefs,
      timeout: const Duration(milliseconds: 20),
      client: MockClient((request) async {
        calls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response('{"status":"ok"}', 200);
      }),
    );
    await expectLater(asleep.getHealth(), throwsA(isA<ApiServerAsleep>()));
    expect(calls, 2);
  });
}
