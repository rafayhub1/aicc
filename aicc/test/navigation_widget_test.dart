import 'package:aicc/core/theme.dart';
import 'package:aicc/models/place.dart';
import 'package:aicc/widgets/place_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const place = CampusPlace(
    id: 'cafe',
    name: 'LGU Cafe',
    aliases: ['canteen'],
    category: 'Food',
    lat: 31.469314,
    lng: 74.405974,
    entranceLat: 31.469314,
    entranceLng: 74.405974,
    building: '',
    floor: '',
    hours: '08:00-20:00',
    description: 'Snacks, lunch and tea.',
    photoUrl: '',
    nodeId: 'cafe',
    isActive: true,
  );

  testWidgets('place card shows the name without a map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const Scaffold(body: PlaceCard(place: place)),
      ),
    );
    await tester.pump();

    expect(find.text('LGU Cafe'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Show on map'), findsNothing);
    expect(find.text('Open in Google Maps'), findsNothing);
  });
}
