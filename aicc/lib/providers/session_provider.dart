import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

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
  String? _loadedUid;

  Future<void> bind(User user, {bool force = false}) async {
    if (!force && _loadedUid == user.uid && (student != null || error != null)) {
      return;
    }
    _loadedUid = user.uid;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final registration = await _profiles.registrationFor(user);
      if (registration == null || registration.isEmpty) {
        throw StateError('This account has no registration number.');
      }
      student = await api.getStudent(registration);
    } catch (caught) {
      student = null;
      error = caught;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    student = null;
    error = null;
    loading = false;
    _loadedUid = null;
    notifyListeners();
  }
}
