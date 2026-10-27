import 'dart:math' as math;

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('The ground sheet is missing a section.');
}

List<dynamic> _list(Map<String, dynamic> parent, String key) {
  final value = parent[key];
  if (value is List) return value;
  throw FormatException('The ground sheet is missing $key.');
}

Map<String, dynamic> _pathways(Map<String, dynamic> sheet) => _map(sheet['pathways']);

String addPlace(
  Map<String, dynamic> sheet, {
  required String name,
  required String kind,
  required double x,
  required double y,
}) {
  final nodes = _list(sheet, 'nodes');
  final prefix = kind == 'building' ? 'gf_building_' : 'gf_node_';
  final id = _nextId(nodes.map((item) => '${_map(item)['id']}'), prefix);
  nodes.add({
    'id': id,
    'name': name.trim(),
    'kind': kind,
    'zone': kind == 'building' ? 'site' : 'mapped',
    'source_x': x,
    'source_y': y,
    'sheet_x': x,
    'sheet_y': y,
  });
  final kinds = sheet['kinds'];
  if (kinds is List && !kinds.contains(kind)) kinds.add(kind);
  _linkToNearest(sheet, id, x, y);
  return id;
}

void movePlace(Map<String, dynamic> sheet, String id, double x, double y) {
  final node = _node(sheet, id);
  if (node == null) return;
  node['sheet_x'] = x;
  node['sheet_y'] = y;
  node['source_x'] = x;
  node['source_y'] = y;
  final link = _link(sheet, id);
  if (link == null) {
    _linkToNearest(sheet, id, x, y);
    return;
  }
  final vertex = _vertex(sheet, '${link['vertex']}');
  if (vertex == null) return;
  link['length'] = _round(
    _distance(x, y, _num(vertex['sheet_x']), _num(vertex['sheet_y'])),
  );
}

void renamePlace(
  Map<String, dynamic> sheet,
  String id, {
  required String name,
  String? kind,
}) {
  final node = _node(sheet, id);
  if (node == null) return;
  node['name'] = name.trim();
  if (kind != null && kind.isNotEmpty) {
    node['kind'] = kind;
    final kinds = sheet['kinds'];
    if (kinds is List && !kinds.contains(kind)) kinds.add(kind);
  }
}

void deletePlace(Map<String, dynamic> sheet, String id) {
  final nodes = _list(sheet, 'nodes');
  nodes.removeWhere((item) => item is Map && item['id'] == id);
  _list(_pathways(sheet), 'links').removeWhere(
    (item) => item is Map && item['room'] == id,
  );
  _entries(sheet).removeWhere((item) => item is Map && item['room'] == id);
}

String addEntry(Map<String, dynamic> sheet, String room, double x, double y) {
  final entries = _entries(sheet);
  final id = _nextId(entries.map((item) => '${_map(item)['id']}'), 'en_');
  entries.add({
    'id': id,
    'room': room,
    'sheet_x': x,
    'sheet_y': y,
  });
  return id;
}

void moveEntry(Map<String, dynamic> sheet, String id, double x, double y) {
  for (final item in _entries(sheet)) {
    if (item is! Map || item['id'] != id) continue;
    final entry = _map(item);
    entry['sheet_x'] = x;
    entry['sheet_y'] = y;
    return;
  }
}

void deleteEntry(Map<String, dynamic> sheet, String id) {
  _entries(sheet).removeWhere((item) => item is Map && item['id'] == id);
}

void addPathway(
  Map<String, dynamic> sheet,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  if (_distance(x1, y1, x2, y2) < 8) return;
  final start = _endpoint(sheet, x1, y1);
  final end = _endpoint(sheet, x2, y2);
  if (start.id == end.id) return;
  final edges = _list(_pathways(sheet), 'edges');
  for (final item in edges) {
    if (item is! Map) continue;
    final a = item['a'];
    final b = item['b'];
    if ((a == start.id && b == end.id) || (a == end.id && b == start.id)) {
      return;
    }
  }
  final length = _round(_distance(start.x, start.y, end.x, end.y));
  edges.add({
    'a': start.id,
    'b': end.id,
    'length': length,
    'points': [
      [start.x, start.y],
      [end.x, end.y],
    ],
  });
}

int pathwayIndexNear(
  Map<String, dynamic> sheet,
  double x,
  double y, {
  double tolerance = 22,
}) {
  final edges = _list(_pathways(sheet), 'edges');
  var best = tolerance;
  var index = -1;
  for (var i = 0; i < edges.length; i++) {
    final item = edges[i];
    if (item is! Map) continue;
    final points = item['points'];
    if (points is! List) continue;
    for (var p = 0; p < points.length - 1; p++) {
      final a = points[p];
      final b = points[p + 1];
      if (a is! List || b is! List || a.length < 2 || b.length < 2) continue;
      final distance = _segmentDistance(
        x,
        y,
        _num(a[0]),
        _num(a[1]),
        _num(b[0]),
        _num(b[1]),
      );
      if (distance < best) {
        best = distance;
        index = i;
      }
    }
  }
  return index;
}

void deletePathwayAt(Map<String, dynamic> sheet, int index) {
  final edges = _list(_pathways(sheet), 'edges');
  if (index < 0 || index >= edges.length) return;
  edges.removeAt(index);
}

void setPathwayStairs(Map<String, dynamic> sheet, int index, bool stairs) {
  final edges = _list(_pathways(sheet), 'edges');
  if (index < 0 || index >= edges.length) return;
  final edge = edges[index];
  if (edge is! Map) return;
  _map(edge)['stairs'] = stairs;
}

bool deletePathwayNear(
  Map<String, dynamic> sheet,
  double x,
  double y, {
  double tolerance = 22,
}) {
  final index = pathwayIndexNear(sheet, x, y, tolerance: tolerance);
  if (index < 0) return false;
  deletePathwayAt(sheet, index);
  return true;
}

({String id, double x, double y}) _endpoint(
  Map<String, dynamic> sheet,
  double x,
  double y,
) {
  final near = _nearestVertex(sheet, x, y);
  if (near != null && near.distance <= 28) {
    return (id: near.id, x: near.x, y: near.y);
  }
  final vertices = _list(_pathways(sheet), 'vertices');
  final id = _nextId(vertices.map((item) => '${_map(item)['id']}'), 'pw_edit_');
  vertices.add({'id': id, 'sheet_x': x, 'sheet_y': y});
  return (id: id, x: x, y: y);
}

void _linkToNearest(Map<String, dynamic> sheet, String room, double x, double y) {
  final near = _nearestVertex(sheet, x, y);
  final String vertexId;
  final double vx;
  final double vy;
  if (near != null) {
    vertexId = near.id;
    vx = near.x;
    vy = near.y;
  } else {
    final created = _endpoint(sheet, x, y);
    vertexId = created.id;
    vx = created.x;
    vy = created.y;
  }
  final links = _list(_pathways(sheet), 'links');
  links.removeWhere((item) => item is Map && item['room'] == room);
  links.add({
    'room': room,
    'vertex': vertexId,
    'length': _round(_distance(x, y, vx, vy)),
  });
}

({String id, double x, double y, double distance})? _nearestVertex(
  Map<String, dynamic> sheet,
  double x,
  double y,
) {
  ({String id, double x, double y, double distance})? best;
  for (final item in _list(_pathways(sheet), 'vertices')) {
    if (item is! Map) continue;
    final vx = _num(item['sheet_x']);
    final vy = _num(item['sheet_y']);
    final distance = _distance(x, y, vx, vy);
    if (best == null || distance < best.distance) {
      best = (id: '${item['id']}', x: vx, y: vy, distance: distance);
    }
  }
  return best;
}

Map<String, dynamic>? _node(Map<String, dynamic> sheet, String id) {
  for (final item in _list(sheet, 'nodes')) {
    if (item is Map && item['id'] == id) return _map(item);
  }
  return null;
}

List<dynamic> _entries(Map<String, dynamic> sheet) {
  final value = sheet['entries'];
  if (value is List) return value;
  final created = <dynamic>[];
  sheet['entries'] = created;
  return created;
}

Map<String, dynamic>? _link(Map<String, dynamic> sheet, String room) {
  for (final item in _list(_pathways(sheet), 'links')) {
    if (item is Map && item['room'] == room) return _map(item);
  }
  return null;
}

Map<String, dynamic>? _vertex(Map<String, dynamic> sheet, String id) {
  for (final item in _list(_pathways(sheet), 'vertices')) {
    if (item is Map && item['id'] == id) return _map(item);
  }
  return null;
}

String _nextId(Iterable<String> existing, String prefix) {
  final taken = existing.toSet();
  var n = 1;
  while (taken.contains('$prefix${n.toString().padLeft(2, '0')}')) {
    n++;
  }
  return '$prefix${n.toString().padLeft(2, '0')}';
}

double _distance(double x1, double y1, double x2, double y2) {
  return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));
}

double _segmentDistance(
  double px,
  double py,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final dx = bx - ax;
  final dy = by - ay;
  final length = dx * dx + dy * dy;
  if (length < 1e-6) return _distance(px, py, ax, ay);
  final t = (((px - ax) * dx + (py - ay) * dy) / length).clamp(0.0, 1.0);
  return _distance(px, py, ax + dx * t, ay + dy * t);
}

double _num(Object? value) => value is num ? value.toDouble() : 0;

double _round(double value) => (value * 100).round() / 100;
