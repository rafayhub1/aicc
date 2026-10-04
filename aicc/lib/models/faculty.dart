import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  const Faculty({
    required this.id,
    required this.fullName,
    required this.department,
    required this.designation,
    required this.subjects,
    required this.classSchedule,
    required this.consultationHours,
    required this.daysOff,
    required this.email,
    required this.phone,
    required this.officeBuilding,
    required this.officeRoom,
    required this.currentStatus,
  });

  final String id;
  final String fullName;
  final String department;
  final String designation;
  final List<String> subjects;
  final String classSchedule;
  final String consultationHours;
  final List<String> daysOff;
  final String email;
  final String phone;
  final String officeBuilding;
  final String officeRoom;
  final String currentStatus;

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'department': department,
      'designation': designation,
      'subjects': subjects,
      'class_schedule': classSchedule,
      'consultation_hours': consultationHours,
      'days_off': daysOff,
      'email': email,
      'phone': phone,
      'office_building': officeBuilding,
      'office_room': officeRoom,
      'current_status': currentStatus,
    };
  }

  factory Faculty.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Faculty(
      id: doc.id,
      fullName: '${data['full_name'] ?? ''}',
      department: '${data['department'] ?? ''}',
      designation: '${data['designation'] ?? ''}',
      subjects: _strings(data['subjects']),
      classSchedule: '${data['class_schedule'] ?? ''}',
      consultationHours: '${data['consultation_hours'] ?? ''}',
      daysOff: _strings(data['days_off']),
      email: '${data['email'] ?? ''}',
      phone: '${data['phone'] ?? ''}',
      officeBuilding: '${data['office_building'] ?? ''}',
      officeRoom: '${data['office_room'] ?? ''}',
      currentStatus: '${data['current_status'] ?? 'Unavailable'}',
    );
  }

  static List<String> _strings(Object? value) {
    if (value is List) {
      return value.map((item) => '$item').toList();
    }
    return const [];
  }
}
