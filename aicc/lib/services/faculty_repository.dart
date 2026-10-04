import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/faculty.dart';
import 'faculty_seed.dart';

class FacultyRepository {
  FacultyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _faculty =>
      _firestore.collection('faculty');

  Future<List<Faculty>> fetchAll({bool seedIfEmpty = true}) async {
    var snapshot = await _faculty.get();
    if (snapshot.docs.isEmpty && seedIfEmpty) {
      await seedSampleFaculty();
      snapshot = await _faculty.get();
    }
    final people = snapshot.docs.map(Faculty.fromDoc).toList();
    people.sort((a, b) => a.fullName.compareTo(b.fullName));
    return people;
  }

  Future<void> seedSampleFaculty() async {
    final batch = _firestore.batch();
    for (final person in sampleFaculty) {
      batch.set(_faculty.doc(person.id), person.toMap());
    }
    await batch.commit();
  }
}
