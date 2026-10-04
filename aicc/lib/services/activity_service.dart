import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_event.dart';

class ActivityService {
  ActivityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('activity_events');

  Future<void> log(String type) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _events.add({
      'user_id': uid,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<List<ActivityEvent>> listForCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];
    final snapshot = await _events.where('user_id', isEqualTo: uid).get();
    final events = snapshot.docs.map(ActivityEvent.fromDoc).toList();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  Future<void> markRead(String eventId) {
    return _events.doc(eventId).update({'read': true});
  }
}
