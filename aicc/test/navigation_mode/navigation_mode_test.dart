import 'package:aicc/core/theme.dart';
import 'package:aicc/features/navigation_mode/domain/sheet_map.dart';
import 'package:aicc/features/navigation_mode/presentation/navigation_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('chemistry lab to the principal room follows the pathway', () async {
    final sheet = await GroundSheet.load();
    final route = sheet.shortest('gf_lab_02', 'gf_office_09');
    expect(route, isNotNull);
    expect(route!.length, 1225.75);
    expect(route.points.first.x, closeTo(983.73, 0.01));
    expect(route.points.last.y, closeTo(1582.19, 0.01));
  });

  testWidgets('Navigation Mode switches between 2D and 2.5D', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const NavigationModeScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Navigation Mode'), findsOneWidget);
    expect(
      find.text('Choose where you are and where you want to go.'),
      findsOneWidget,
    );
    expect(find.text('2D'), findsOneWidget);
    expect(find.text('2.5D'), findsOneWidget);
    expect(find.byKey(const Key('nav-tilt')), findsNothing);

    await tester.tap(find.text('2.5D'));
    await tester.pump();
    expect(find.byKey(const Key('nav-tilt')), findsOneWidget);
    expect(find.byKey(const Key('nav-turn')), findsOneWidget);

    await tester.tap(find.text('3D'));
    await tester.pump();
    expect(find.text('3D'), findsOneWidget);
    expect(find.byKey(const Key('nav-tilt')), findsOneWidget);
    expect(find.byKey(const Key('nav-turn')), findsOneWidget);

    await tester.tap(find.text('2D'));
    await tester.pump();
    expect(find.byKey(const Key('nav-tilt')), findsNothing);
  });

  testWidgets('a finger drag orbits the 3D map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const NavigationModeScreen()),
    );
    for (var attempt = 0; attempt < 8; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
      if (find.byKey(const Key('nav-map')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const Key('nav-map')), findsOneWidget);

    await tester.tap(find.text('3D'));
    await tester.pump();
    final beforeTurn = tester
        .widget<Slider>(find.byKey(const Key('nav-turn')))
        .value;
    final beforeTilt = tester
        .widget<Slider>(find.byKey(const Key('nav-tilt')))
        .value;

    await tester.drag(find.byKey(const Key('nav-map')), const Offset(140, -40));
    await tester.pump();

    final turn = tester.widget<Slider>(find.byKey(const Key('nav-turn'))).value;
    final tilt = tester.widget<Slider>(find.byKey(const Key('nav-tilt'))).value;
    expect((turn - beforeTurn).abs(), greaterThan(8));
    expect((tilt - beforeTilt).abs(), greaterThan(4));
  });

  testWidgets('search picks a current location and a destination', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const NavigationModeScreen()),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const Key('nav-from')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Search places'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byKey(const Key('nav-place-search')), 'chem');
    await tester.pump();
    expect(find.text('Chemistry lab'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('place-gf_lab_02')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('nav-to')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const Key('nav-place-search')),
      'principal',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('place-gf_office_09')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Shortest path · about 170 meters'), findsOneWidget);
  });
}
