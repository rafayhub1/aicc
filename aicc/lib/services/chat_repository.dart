import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in before using chat.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('chat_sessions');

  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('chat_messages');

  Future<String> createSession(String title) async {
    final doc = await _sessions.add({
      'user_id': _uid,
      'title': title,
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> addMessage(ChatMessage message) {
    return _messages.add(message.toMap());
  }

  Future<List<ChatSession>> listSessions() async {
    final snapshot = await _sessions.where('user_id', isEqualTo: _uid).get();
    final sessions = snapshot.docs.map(ChatSession.fromDoc).toList();
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  Future<List<ChatMessage>> listMessages(String sessionId) async {
    final docs = await _messageDocs(sessionId);
    final messages = docs.map(ChatMessage.fromDoc).toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> deleteSession(String sessionId) async {
    await _deleteMessages(sessionId);
    await _sessions.doc(sessionId).delete();
  }

  Future<void> deleteSessions(Iterable<String> sessionIds) async {
    for (final id in sessionIds) {
      await deleteSession(id);
    }
  }

  Future<void> _deleteMessages(String sessionId) async {
    final docs = await _messageDocs(sessionId);
    if (docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _messageDocs(
    String sessionId,
  ) async {
    final snapshot = await _messages.where('user_id', isEqualTo: _uid).get();
    return snapshot.docs
        .where((doc) => doc.data()['session_id'] == sessionId)
        .toList();
  }
}
