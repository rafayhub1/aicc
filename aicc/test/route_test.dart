import 'package:aicc/screens/navigation/campus_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route walks the fixed hubs between two buildings', () {
    final points = campusRoute('cs', 'library');
    expect(points.first, placeById('cs')!.center);
    expect(points.last, placeById('library')!.center);
    expect(points.length, greaterThan(2));
    expect(campusRoute('gate', 'gate'), isEmpty);
  });
}
