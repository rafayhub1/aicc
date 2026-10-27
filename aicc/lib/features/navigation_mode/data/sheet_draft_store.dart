import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Admin edits to the ground-floor sheet. Navigation Mode reads the same copy.
class SheetDraftStore {
  static const key = 'navigation_sheet_draft_v1';

  static Future<Map<String, dynamic>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(Map<String, dynamic> sheet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(sheet));
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
