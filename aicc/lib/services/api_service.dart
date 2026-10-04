import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../models/app_notification.dart';
import '../models/catalog.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import 'api_exception.dart';

class ApiService {
  ApiService(this._prefs, {http.Client? client}) : _client = client ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _client;

  String get baseUrl {
    final saved = _prefs.getString(kApiBaseUrlPrefsKey);
    final raw = (saved == null || saved.trim().isEmpty)
        ? kDefaultApiBaseUrl
        : saved.trim();
    return raw.replaceAll(RegExp(r'/+$'), '');
  }

  Future<void> setBaseUrl(String url) {
    return _prefs.setString(
      kApiBaseUrlPrefsKey,
      url.trim().replaceAll(RegExp(r'/+$'), ''),
    );
  }

  Future<Map<String, dynamic>> getHealth() async {
    final body = await _get('/health');
    return body is Map<String, dynamic> ? body : {'status': body};
  }

  Future<Catalog> getCatalog() async {
    final body = await _get('/api/catalog');
    return Catalog.fromJson(_asMap(body));
  }

  Future<Student> getStudent(String registrationNumber) async {
    final id = registrationNumber.trim().toUpperCase();
    final body = await _get('/api/students/$id');
    return Student.fromJson(_asMap(body));
  }

  Future<List<Course>> getCourses(String studentId, {int? semester}) async {
    final query = semester == null ? '' : '?semester=$semester';
    final body = await _get('/api/students/$studentId/courses$query');
    return _asList(body).map(Course.fromJson).toList();
  }

  Future<List<AppNotification>> getNotifications(String studentId) async {
    final body = await _get('/api/students/$studentId/notifications');
    return _asList(body).map(AppNotification.fromJson).toList();
  }

  Future<List<StudentDocument>> getDocuments(String studentId) async {
    final body = await _get('/api/students/$studentId/documents');
    return _asList(body).map(StudentDocument.fromJson).toList();
  }

  Future<void> markNotificationRead(String studentId, String notificationId) async {
    await _send(
      () => _client.patch(
        _uri('/api/students/$studentId/notifications/$notificationId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'read': true}),
      ),
    );
  }

  Future<Object?> _get(String path) async {
    final response = await _send(() => _client.get(_uri(path)));
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await call().timeout(const Duration(seconds: 60));
        if (response.statusCode == 404) {
          throw const ApiNotFound(
            'Registration number not found in university records.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiUnknown(_errorMessage(response));
        }
        return response;
      } on ApiException {
        rethrow;
      } on TimeoutException catch (error) {
        lastError = error;
      } catch (error) {
        lastError = error;
        if (!_isOffline(error)) break;
      }
    }
    if (lastError is TimeoutException) throw const ApiServerAsleep();
    if (_isOffline(lastError)) throw const ApiOffline();
    throw ApiUnknown('Could not reach the university server.');
  }

  bool _isOffline(Object? error) {
    final text = '$error'.toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused');
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        return '${decoded['detail']}';
      }
    } catch (_) {}
    return 'The server returned an unexpected response (${response.statusCode}).';
  }

  Map<String, dynamic> _asMap(Object? body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return {};
  }

  List<Map<String, dynamic>> _asList(Object? body) {
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
