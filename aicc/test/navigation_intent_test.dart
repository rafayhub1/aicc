import 'dart:convert';
import 'dart:io';

import 'package:aicc/chat/intent.dart';
import 'package:aicc/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final places = [
    for (final item in jsonDecode(File('assets/maps/places.json').readAsStringSync()) as List)
      CampusPlace.fromJson(Map<String, dynamic>.from(item as Map)),
  ];

  test('place questions are answered by the router, not the faculty lookup', () {
    expect(classifyIntent('LGU', places: places).placeId, 'lgu');
    expect(classifyIntent('where is LGU cafe', places: places).placeId, 'cafe');
    expect(classifyIntent('where is fountain ground', places: places).placeId, 'fountain');
    expect(classifyIntent('navigate to canteen', places: places).placeId, 'cafe');
    expect(classifyIntent('library kahan hai', places: places).placeId, 'library');
    expect(classifyIntent('where is Dr. Hamza Qureshi', places: places).kind, ChatIntentKind.faculty);
    expect(classifyIntent('when does the library open?', places: places).kind, isNot(ChatIntentKind.navigation));
    expect(classifyIntent('where can I eat lunch?', places: places).kind, isNot(ChatIntentKind.navigation));
  });
}
