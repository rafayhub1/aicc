import 'package:aicc/features/navigation_mode/domain/sheet_editor.dart';
import 'package:aicc/features/navigation_mode/domain/sheet_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a route without doors still ends at the room', () {
    final route = GroundSheet.parse(_corridor()).shortest('start', 'dest');
    expect(route, isNotNull);
    expect(route!.length, 140);
    expect(route.points.first.y, -20);
    expect(route.points.last.x, 100);
    expect(route.points.last.y, -20);
  });

  test('A* walks to the door that makes the shortest entrance', () {
    final sheet = _corridor();
    addEntry(sheet, 'dest', 0, 30);
    addEntry(sheet, 'dest', 100, 10);
    final route = GroundSheet.parse(sheet).shortest('start', 'dest');
    expect(route, isNotNull);
    expect(route!.length, 50);
    expect(route.points.first.x, 0);
    expect(route.points.first.y, -20);
    expect(route.points.last.x, 0);
    expect(route.points.last.y, 30);
  });

  test('leaving and arriving both use the closest doors', () {
    final sheet = _corridor();
    addEntry(sheet, 'start', 0, 4);
    addEntry(sheet, 'dest', 100, 10);
    final route = GroundSheet.parse(sheet).shortest('start', 'dest');
    expect(route, isNotNull);
    expect(route!.length, 114);
    expect(route.points.first.y, 4);
    expect(route.points.last.x, 100);
    expect(route.points.last.y, 10);
  });
}

Map<String, dynamic> _corridor() {
  return {
    'coordinate_space': {
      'page_size': [1000.0, 800.0],
    },
    'kinds': ['classroom'],
    'nodes': [
      {
        'id': 'start',
        'name': 'Start',
        'kind': 'classroom',
        'zone': 'a',
        'sheet_x': 0.0,
        'sheet_y': -20.0,
      },
      {
        'id': 'dest',
        'name': 'Dest',
        'kind': 'classroom',
        'zone': 'a',
        'sheet_x': 100.0,
        'sheet_y': -20.0,
      },
    ],
    'pathways': {
      'vertices': [
        {'id': 'a', 'sheet_x': 0.0, 'sheet_y': 0.0},
        {'id': 'b', 'sheet_x': 100.0, 'sheet_y': 0.0},
      ],
      'edges': [
        {
          'a': 'a',
          'b': 'b',
          'length': 100.0,
          'points': [
            [0.0, 0.0],
            [100.0, 0.0],
          ],
        },
      ],
      'links': [
        {'room': 'start', 'vertex': 'a', 'length': 20.0},
        {'room': 'dest', 'vertex': 'b', 'length': 20.0},
      ],
    },
  };
}
