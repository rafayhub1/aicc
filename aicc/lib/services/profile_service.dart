import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveRegistration(User user, String registrationNumber) {
    return _firestore.collection('users').doc(user.uid).set({
      'registrationNumber': registrationNumber.trim().toUpperCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> registrationFor(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final stored = doc.data()?['registrationNumber'];
    if (stored is String && stored.trim().isNotEmpty) {
      return stored.trim().toUpperCase();
    }
    final email = user.email ?? '';
    final local = email.split('@').first.trim();
    if (local.isEmpty) return null;
    return local.toUpperCase();
  }
}
