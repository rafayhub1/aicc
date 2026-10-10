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
    Future<void> Function()? bootstrap,
  }) async {
    try {
      return await _signIn(registrationNumber, password);
    } on FirebaseAuthException catch (error) {
      final username = !registrationPattern.hasMatch(registrationNumber.trim());
      final missing = error.code == 'user-not-found' ||
          error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'invalid-login-credentials';
      if (username && missing && bootstrap != null) {
        await bootstrap();
        return _signIn(registrationNumber, password);
      }
      rethrow;
    }
  }

  Future<bool> isAdmin(User user) async {
    final result = await user.getIdTokenResult(true);
    return result.claims?['admin'] == true;
  }

  Future<User> _signIn(String registrationNumber, String password) async {
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
  }

  Future<void> signOut() => _auth.signOut();
}

const String kLoginErrorMessage = 'Registration number or password is incorrect.';

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
  return kLoginErrorMessage;
}
