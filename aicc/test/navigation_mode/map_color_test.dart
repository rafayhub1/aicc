import 'package:aicc/features/navigation_mode/domain/map_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('room sizes become sheet spans and surfaces keep their colors', () {
    final span = parseRoomSpan('21\'-0"x24\'-0"');
    expect(span, isNotNull);
    expect(span!.a, closeTo(21 * sheetPointsPerFoot, 0.01));
    expect(span.b, closeTo(24 * sheetPointsPerFoot, 0.01));
    expect(parseRoomSpan('41\'-9"x25\'-0"')!.a, closeTo(41.75 * sheetPointsPerFoot, 0.01));

    expect(campusSurface('playground'), CampusSurface.ground);
    expect(campusSurface('courtyard'), CampusSurface.ground);
    expect(campusSurface('classroom'), CampusSurface.building);
    expect(campusSurface('office'), CampusSurface.building);
    expect(campusSurface('paved'), CampusSurface.paved);
    expect(campusSurface('corridor'), CampusSurface.paved);
    expect(campusSurface('parking'), CampusSurface.paved);
  });
}
