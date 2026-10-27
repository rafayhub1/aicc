import 'dart:convert';
import 'dart:io';

import 'package:aicc/models/place.dart';
import 'package:aicc/services/place_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final places = _loadPlaces();

  test('longest place name wins over a shorter one', () {
    expect(matchPlace('where is LGU cafe', places)?.id, 'cafe');
    expect(matchPlace('LGU', places)?.id, 'lgu');
  });

  test('aliases and roman urdu questions find the place', () {
    expect(matchPlace('where is fountain ground', places)?.id, 'fountain');
    expect(matchPlace('navigate to canteen', places)?.id, 'cafe');
    expect(matchPlace('library kahan hai', places)?.id, 'library');
  });

  test('a sentence that only mentions a place is not navigation', () {
    expect(matchPlace('when does the library open?', places), isNull);
    expect(matchPlace('where can I eat lunch?', places), isNull);
  });

  test('a one-letter typo still finds a long place word', () {
    expect(matchPlace('where is the libary', places)?.id, 'library');
  });

  test('open hours follow the clock', () {
    expect(placeOpenNow('08:00-20:00', DateTime(2026, 10, 13, 12)), isTrue);
    expect(placeOpenNow('08:00-20:00', DateTime(2026, 10, 13, 21)), isFalse);
    expect(hoursKnown('all day'), isFalse);
  });
}

List<CampusPlace> _loadPlaces() {
  final raw = jsonDecode(File('assets/maps/places.json').readAsStringSync()) as List;
  return [
    for (final item in raw) CampusPlace.fromJson(Map<String, dynamic>.from(item as Map)),
  ];
}
