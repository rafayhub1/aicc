import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class PushService {
  PushService({required this.api});

  final ApiService api;

  String? _studentId;
  String? _token;
  StreamSubscription<String>? _refresh;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get openedMessages => FirebaseMessaging.onMessageOpenedApp;

  Future<RemoteMessage?> initialMessage() => FirebaseMessaging.instance.getInitialMessage();

  Future<void> register(String studentId) async {
    if (_studentId == studentId && _token != null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token == null) return;
      await api.registerPushToken(studentId, token);
      _studentId = studentId;
      _token = token;
      await _refresh?.cancel();
      _refresh = messaging.onTokenRefresh.listen((fresh) async {
        final id = _studentId;
        if (id == null) return;
        _token = fresh;
        try {
          await api.registerPushToken(id, fresh);
        } catch (error) {
          debugPrint('Push token refresh failed: $error');
        }
      });
    } catch (error) {
      debugPrint('Push registration failed: $error');
    }
  }

  Future<void> unregister() async {
    final id = _studentId;
    final token = _token;
    _studentId = null;
    _token = null;
    await _refresh?.cancel();
    _refresh = null;
    try {
      if (id != null && token != null) await api.unregisterPushToken(id, token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Push unregister failed: $error');
    }
  }
}
