import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

enum SessionRole { unknown, student, admin }

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    required this.api,
    ProfileService? profiles,
  }) : _profiles = profiles ?? ProfileService();

  final ApiService api;
  final ProfileService _profiles;

  Student? student;
  Object? error;
  bool loading = false;
  SessionRole role = SessionRole.unknown;
  String? _loadedUid;

  bool get isAdmin => role == SessionRole.admin;

  Future<void> bind(User user, {bool force = false}) async {
    if (!force && _loadedUid == user.uid && role != SessionRole.unknown && error == null) {
      return;
    }
    _loadedUid = user.uid;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final token = await user.getIdTokenResult(true);
      if (token.claims?['admin'] == true) {
        role = SessionRole.admin;
        student = null;
        return;
      }
      role = SessionRole.student;
      final registration = await _profiles.registrationFor(user);
      if (registration == null || registration.isEmpty) {
        throw StateError('This account has no registration number.');
      }
      student = await api.getStudent(registration);
    } catch (caught) {
      if (role != SessionRole.admin) {
        student = null;
        role = SessionRole.student;
        error = caught;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    student = null;
    error = null;
    loading = false;
    role = SessionRole.unknown;
    _loadedUid = null;
    notifyListeners();
  }
}
