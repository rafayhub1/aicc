import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../models/admin_activity.dart';
import '../models/app_account.dart';
import '../models/app_notification.dart';
import '../models/campus_stats.dart';
import '../models/catalog.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import 'api_exception.dart';

class ApiService {
  ApiService(
    this._prefs, {
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
    this.tokenProvider,
  }) : _client = client ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _client;
  final Duration timeout;
  final Future<String?> Function()? tokenProvider;

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

  Future<String> askAssistant(
    String message,
    List<({String role, String content})> history,
  ) async {
    final recent = history.length <= 6 ? history : history.sublist(history.length - 6);
    final response = await _client
        .post(
          _uri('/api/chat'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message.length <= 1000 ? message : message.substring(0, 1000),
            'history': [
              for (final turn in recent)
                {
                  'role': turn.role == 'user' ? 'user' : 'assistant',
                  'content': turn.content.length <= 800
                      ? turn.content
                      : turn.content.substring(0, 800),
                },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiUnknown('The campus assistant could not answer right now.');
    }
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    return '${_asMap(body)['text'] ?? ''}'.trim();
  }

  Future<String> transcribeSpeech(String path) async {
    final request = http.MultipartRequest('POST', _uri('/api/chat/transcribe'));
    request.files.add(
      await http.MultipartFile.fromPath('file', path, filename: 'speech.m4a'),
    );
    final streamed = await _client.send(request).timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiUnknown(_errorMessage(response));
    }
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    return '${_asMap(body)['text'] ?? ''}'.trim();
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

  Future<void> bootstrapAdmin() async {
    await _json('POST', '/api/admin/bootstrap');
  }

  Future<CampusStats> getStats() async {
    return CampusStats.fromJson(_asMap(await _get('/api/stats')));
  }

  Future<List<Student>> listStudents() async {
    return _asList(await _get('/api/students')).map(Student.fromJson).toList();
  }

  Future<Student> createStudent(Map<String, dynamic> payload) async {
    final body = await _json('POST', '/api/students', jsonBody: payload);
    return Student.fromJson(_asMap(body));
  }

  Future<Student> updateStudent(String id, Map<String, dynamic> payload) async {
    final body = await _json('PUT', '/api/students/${_id(id)}', jsonBody: payload);
    return Student.fromJson(_asMap(body));
  }

  Future<void> deleteStudentFully(String id) async {
    await _json('DELETE', '/api/admin/students/${_id(id)}', admin: true);
  }

  Future<Course> createCourse(String studentId, Map<String, dynamic> payload) async {
    final body = await _json(
      'POST',
      '/api/students/${_id(studentId)}/courses',
      jsonBody: payload,
    );
    return Course.fromJson(_asMap(body));
  }

  Future<Course> updateCourse(
    String studentId,
    String courseId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _json(
      'PUT',
      '/api/students/${_id(studentId)}/courses/$courseId',
      jsonBody: payload,
    );
    return Course.fromJson(_asMap(body));
  }

  Future<void> deleteCourse(String studentId, String courseId) async {
    await _json('DELETE', '/api/students/${_id(studentId)}/courses/$courseId');
  }

  Future<StudentDocument> createDocument(
    String studentId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _json(
      'POST',
      '/api/students/${_id(studentId)}/documents',
      jsonBody: payload,
    );
    return StudentDocument.fromJson(_asMap(body));
  }

  Future<StudentDocument> updateDocument(
    String studentId,
    String documentId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _json(
      'PATCH',
      '/api/students/${_id(studentId)}/documents/$documentId',
      jsonBody: payload,
    );
    return StudentDocument.fromJson(_asMap(body));
  }

  Future<void> deleteDocument(String studentId, String documentId) async {
    await _json('DELETE', '/api/students/${_id(studentId)}/documents/$documentId');
  }

  Future<AppNotification> createNotification(
    String studentId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _json(
      'POST',
      '/api/students/${_id(studentId)}/notifications',
      jsonBody: payload,
    );
    return AppNotification.fromJson(_asMap(body));
  }

  Future<void> deleteNotification(String studentId, String notificationId) async {
    await _json(
      'DELETE',
      '/api/students/${_id(studentId)}/notifications/$notificationId',
    );
  }

  Future<AppAccount> getAccount(String identifier) async {
    final body = await _json('GET', '/api/admin/accounts/${_id(identifier)}', admin: true);
    return AppAccount.fromJson(_asMap(body));
  }

  Future<void> setAccountPassword(String identifier, String password) async {
    await _json(
      'POST',
      '/api/admin/accounts/${_id(identifier)}/password',
      jsonBody: {'password': password},
      admin: true,
    );
  }

  Future<void> deleteAccount(String identifier) async {
    await _json('DELETE', '/api/admin/accounts/${_id(identifier)}', admin: true);
  }

  Future<int> broadcastNotification({
    required String message,
    required String type,
    String? department,
    int? semester,
    String? section,
  }) async {
    final body = await _json(
      'POST',
      '/api/admin/notifications/broadcast',
      jsonBody: {
        'message': message,
        'type': type,
        if (department != null && department.isNotEmpty) 'department': department,
        'semester': ?semester,
        if (section != null && section.isNotEmpty) 'section': section,
      },
      admin: true,
    );
    final count = _asMap(body)['count'];
    if (count is num) return count.round();
    return int.tryParse('$count') ?? 0;
  }

  Future<List<AdminActivity>> listActivity() async {
    final body = await _json('GET', '/api/admin/activity?limit=100', admin: true);
    return _asList(body).map(AdminActivity.fromJson).toList();
  }

  Future<Object?> _get(String path) async {
    final response = await _send(() => _client.get(_uri(path)));
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  String _id(String value) => Uri.encodeComponent(value.trim());

  Future<Object?> _json(
    String method,
    String path, {
    Object? jsonBody,
    bool admin = false,
  }) async {
    final headers = <String, String>{};
    if (jsonBody != null) headers['Content-Type'] = 'application/json';
    if (admin) {
      final token = await tokenProvider?.call();
      if (token == null || token.isEmpty) {
        throw const ApiUnknown('Sign in again to continue.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    final encoded = jsonBody == null ? null : jsonEncode(jsonBody);
    final response = await _send(() {
      final uri = _uri(path);
      return switch (method) {
        'POST' => _client.post(uri, headers: headers, body: encoded),
        'PUT' => _client.put(uri, headers: headers, body: encoded),
        'PATCH' => _client.patch(uri, headers: headers, body: encoded),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.get(uri, headers: headers),
      };
    }, keepNotFoundMessage: method != 'GET' || admin);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> _send(
    Future<http.Response> Function() call, {
    bool keepNotFoundMessage = false,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await call().timeout(timeout);
        if (response.statusCode == 404) {
          throw ApiNotFound(
            keepNotFoundMessage
                ? _errorMessage(response)
                : 'Registration number not found in university records.',
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
