import 'package:aicc/features/navigation_mode/domain/sheet_editor.dart';
import 'package:aicc/features/navigation_mode/domain/sheet_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin edits add, move, rename, and remove places and pathways', () {
    final sheet = _sample();

    final building = addPlace(
      sheet,
      name: 'Block A',
      kind: 'building',
      x: 300,
      y: 180,
    );
    expect(building, 'gf_building_01');
    expect(GroundSheet.parse(sheet).nodeById(building)?.name, 'Block A');

    movePlace(sheet, building, 320, 200);
    expect(GroundSheet.parse(sheet).nodeById(building)?.x, 320);

    renamePlace(sheet, building, name: 'Science block', kind: 'building');
    expect(GroundSheet.parse(sheet).nodeById(building)?.name, 'Science block');

    addPathway(sheet, 120, 120, 400, 120);
    setPathwayStairs(sheet, 0, true);
    expect(GroundSheet.parse(sheet).edges.first.stairs, isTrue);
    final before = GroundSheet.parse(sheet).edges.length;
    expect(before, 2);
    expect(deletePathwayNear(sheet, 160, 120), isTrue);
    expect(GroundSheet.parse(sheet).edges.length, 1);

    deletePlace(sheet, building);
    expect(GroundSheet.parse(sheet).nodeById(building), isNull);
  });

  test('doors can be added, moved, and removed with their place', () {
    final sheet = _sample();
    final id = addEntry(sheet, 'gf_classroom_01', 130, 140);
    expect(id, 'en_01');
    moveEntry(sheet, id, 150, 160);
    expect(GroundSheet.parse(sheet).entryById(id)?.x, 150);
    expect(GroundSheet.parse(sheet).entryById(id)?.y, 160);

    deletePlace(sheet, 'gf_classroom_01');
    expect(GroundSheet.parse(sheet).entries, isEmpty);
  });
}

Map<String, dynamic> _sample() {
  return {
    'coordinate_space': {
      'page_size': [1000.0, 800.0],
    },
    'kinds': ['classroom'],
    'nodes': [
      {
        'id': 'gf_classroom_01',
        'name': 'Classroom',
        'kind': 'classroom',
        'zone': 'block_a',
        'sheet_x': 100.0,
        'sheet_y': 100.0,
      },
    ],
    'pathways': {
      'vertices': [
        {'id': 'pw_0001', 'sheet_x': 120.0, 'sheet_y': 120.0},
        {'id': 'pw_0002', 'sheet_x': 200.0, 'sheet_y': 120.0},
      ],
      'edges': [
        {
          'a': 'pw_0001',
          'b': 'pw_0002',
          'length': 80.0,
          'points': [
            [120.0, 120.0],
            [200.0, 120.0],
          ],
        },
      ],
      'links': [
        {'room': 'gf_classroom_01', 'vertex': 'pw_0001', 'length': 28.28},
      ],
    },
  };
}
