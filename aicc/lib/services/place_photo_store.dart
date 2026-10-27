import 'dart:io';

import 'package:http/http.dart' as http;

/// Public photo files for campus places. The anon key is a client key.
/// Writes are limited by the `places` bucket policies in Supabase.
class PlacePhotoStore {
  static const _projectUrl = 'https://qmzqhbefsenetuyapmxt.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtenFoYmVmc2VuZXR1eWFwbXh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MTY5ODUsImV4cCI6MjEwODQ5Mjk4NX0.Wuu4BLJTUO6JRJsRYHuJ4mGeB5-57W6tKNJMfSyGO2c';

  static Future<String> upload(File file, String placeId) async {
    final name = placeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final objectPath = 'places/$name.jpg';
    final response = await http.post(
      Uri.parse('$_projectUrl/storage/v1/object/$objectPath'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
      },
      body: await file.readAsBytes(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Photo upload failed (${response.statusCode}). ${response.body}');
    }
    return '$_projectUrl/storage/v1/object/public/$objectPath';
  }
}
