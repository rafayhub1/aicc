import 'package:intl/intl.dart';

const departmentNames = {
  'BSCS': 'Computer Science',
  'BBA': 'Business Administration',
  'BSPSY': 'Psychology',
};

String departmentLabel(String code) => departmentNames[code] ?? code;

String greetingFor(DateTime time) {
  final hour = time.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String firstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'Student';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _firstLetter(String word) {
  final trimmed = word.trim();
  if (trimmed.isEmpty) return '';
  return trimmed[0].toUpperCase();
}

String initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'A';
  if (parts.length == 1) return _firstLetter(parts.first);
  return '${_firstLetter(parts.first)}${_firstLetter(parts.last)}';
}

String relativeTime(DateTime time) {
  final local = time.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(local);
}

String chatTitleFrom(String text) {
  final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.isEmpty) return 'New chat';
  if (clean.length <= 42) return clean;
  return '${clean.substring(0, 42).trim()}…';
}

String internalEmailFor(String registrationNumber) {
  return '${registrationNumber.trim().toLowerCase()}@aicc-demo.local';
}

final registrationPattern = RegExp(r'^[A-Za-z]{2}\d{2}-[A-Za-z]+-\d{3}$');
final usernamePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,}$');

String? validateLoginIdentifier(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Enter your registration number';
  if (registrationPattern.hasMatch(trimmed) || usernamePattern.hasMatch(trimmed)) {
    return null;
  }
  return 'Use the format FA26-BSCS-001';
}

String? validateStudentRegistration(String value, String department) {
  final format = validateRegistration(value);
  if (format != null) return format;
  final parts = value.trim().toUpperCase().split('-');
  if (parts.length == 3 && parts[1] != department) {
    return 'The registration number must include $department';
  }
  return null;
}

String? validateRegistration(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Enter your registration number';
  if (!registrationPattern.hasMatch(trimmed)) {
    return 'Use the format FA26-BSCS-001';
  }
  return null;
}

String? validatePassword(String value) {
  if (value.isEmpty) return 'Enter a password';
  if (value.length < 6) return 'Use at least 6 characters';
  return null;
}
