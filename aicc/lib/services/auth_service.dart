import 'package:firebase_auth/firebase_auth.dart';

import '../core/formatters.dart';
import '../models/student.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authState() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> createAccount({
    required Student student,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: internalEmailFor(student.registrationNumber),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-missing',
          message: 'Account could not be created.',
        );
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<User> signIn({
    required String registrationNumber,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: internalEmailFor(registrationNumber),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-missing',
          message: 'Could not sign in.',
        );
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}

String authErrorMessage(FirebaseAuthException error, {required bool signup}) {
  if (signup && error.code == 'email-already-in-use') {
    return 'An account already exists for this registration number. Log in instead.';
  }
  if (signup && error.code == 'weak-password') {
    return 'Use at least 6 characters for the password.';
  }
  if (signup) {
    return 'The account could not be created. Check the details and try again.';
  }
  return 'Registration number or password is incorrect.';
}
