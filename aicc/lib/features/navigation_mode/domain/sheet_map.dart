import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../data/sheet_draft_store.dart';

class SheetPoint {
  const SheetPoint(this.x, this.y);

  final double x;
  final double y;
}

class SheetNode {
  const SheetNode({
    required this.id,
    required this.name,
    required this.kind,
    required this.zone,
    required this.x,
    required this.y,
    this.size,
  });

  final String id;
  final String name;
  final String kind;
  final String zone;
  final double x;
  final double y;
  final String? size;
}

class SheetEdge {
  const SheetEdge({
    required this.a,
    required this.b,
    required this.length,
    required this.points,
    this.stairs = false,
  });

  final String a;
  final String b;
  final double length;
  final List<SheetPoint> points;
  final bool stairs;
}

class SheetEntry {
  const SheetEntry({
    required this.id,
    required this.room,
    required this.x,
    required this.y,
  });

  final String id;
  final String room;
  final double x;
  final double y;
}

class SheetLink {
  const SheetLink({
    required this.vertex,
    required this.length,
  });

  final String vertex;
  final double length;
}

class SheetRoute {
  const SheetRoute({required this.length, required this.points});

  final double length;
  final List<SheetPoint> points;
}

class _Hop {
  const _Hop(this.to, this.length, this.points, this.stairs);

  final String to;
  final double length;
  final List<SheetPoint> points;
  final bool stairs;
}

class GroundSheet {
  GroundSheet._({
    required this.pageWidth,
    required this.pageHeight,
    required this.nodes,
    required this.edges,
    required this.entries,
    required this._entriesByRoom,
    required this._links,
    required this._graph,
    required this._positions,
  });

  final double pageWidth;
  final double pageHeight;
  final List<SheetNode> nodes;
  final List<SheetEdge> edges;
  final List<SheetEntry> entries;
  final Map<String, List<SheetEntry>> _entriesByRoom;
  final Map<String, SheetLink> _links;
  final Map<String, List<_Hop>> _graph;
  final Map<String, SheetPoint> _positions;

  static const asset = 'assets/navigation/nodes.json';
  static const floorAsset = 'assets/navigation/floor.png';

  static Future<GroundSheet> load() async {
    final saved = await SheetDraftStore.read();
    if (saved != null) {
      try {
        return GroundSheet.parse(saved);
      } catch (_) {}
    }
    final raw = jsonDecode(await rootBundle.loadString(asset));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Ground sheet is not an object.');
    }
    return GroundSheet.parse(raw);
  }

  factory GroundSheet.parse(Map<String, dynamic> raw) {
    final space = raw['coordinate_space'];
    if (space is! Map<String, dynamic>) {
      throw const FormatException('Ground sheet has no coordinate space.');
    }
    final page = space['page_size'];
    if (page is! List || page.length < 2) {
      throw const FormatException('Ground sheet page size is missing.');
    }
    final nodes = <SheetNode>[];
    final nodeList = raw['nodes'];
    if (nodeList is! List) {
      throw const FormatException('Ground sheet nodes are missing.');
    }
    for (final item in nodeList) {
      if (item is! Map<String, dynamic>) continue;
      nodes.add(
        SheetNode(
          id: item['id'] as String,
          name: item['name'] as String,
          kind: item['kind'] as String,
          zone: item['zone'] as String,
          x: (item['sheet_x'] as num).toDouble(),
          y: (item['sheet_y'] as num).toDouble(),
          size: item['size'] is String ? item['size'] as String : null,
        ),
      );
    }
    final pathways = raw['pathways'];
    if (pathways is! Map<String, dynamic>) {
      throw const FormatException('Ground sheet pathways are missing.');
    }
    final edges = <SheetEdge>[];
    final graph = <String, List<_Hop>>{};
    final edgeList = pathways['edges'];
    if (edgeList is! List) {
      throw const FormatException('Ground sheet edges are missing.');
    }
    for (final item in edgeList) {
      if (item is! Map<String, dynamic>) continue;
      final points = _points(item['points']);
      final length = (item['length'] as num).toDouble();
      final a = item['a'] as String;
      final b = item['b'] as String;
      final stairs = _stairs(item['stairs'], points, nodes);
      edges.add(
        SheetEdge(a: a, b: b, length: length, points: points, stairs: stairs),
      );
      _remember(graph, a, b, length, points, stairs);
      _remember(graph, b, a, length, points.reversed.toList(), stairs);
    }
    final positions = <String, SheetPoint>{};
    final vertexList = pathways['vertices'];
    if (vertexList is List) {
      for (final item in vertexList) {
        if (item is! Map<String, dynamic>) continue;
        positions[item['id'] as String] = SheetPoint(
          (item['sheet_x'] as num).toDouble(),
          (item['sheet_y'] as num).toDouble(),
        );
      }
    }
    final links = <String, SheetLink>{};
    final linkList = pathways['links'];
    if (linkList is! List) {
      throw const FormatException('Ground sheet links are missing.');
    }
    for (final item in linkList) {
      if (item is! Map<String, dynamic>) continue;
      links[item['room'] as String] = SheetLink(
        vertex: item['vertex'] as String,
        length: (item['length'] as num).toDouble(),
      );
    }
    final entries = <SheetEntry>[];
    final entriesByRoom = <String, List<SheetEntry>>{};
    final entryList = raw['entries'];
    if (entryList is List) {
      for (final item in entryList) {
        if (item is! Map) continue;
        final id = item['id'];
        final room = item['room'];
        final x = item['sheet_x'];
        final y = item['sheet_y'];
        if (id is! String || room is! String || x is! num || y is! num) continue;
        final entry = SheetEntry(
          id: id,
          room: room,
          x: x.toDouble(),
          y: y.toDouble(),
        );
        entries.add(entry);
        entriesByRoom.putIfAbsent(room, () => []).add(entry);
      }
    }
    return GroundSheet._(
      pageWidth: (page[0] as num).toDouble(),
      pageHeight: (page[1] as num).toDouble(),
      nodes: nodes,
      edges: edges,
      entries: entries,
      entriesByRoom: entriesByRoom,
      links: links,
      graph: graph,
      positions: positions,
    );
  }

  SheetEntry? entryById(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  SheetNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  SheetRoute? shortest(String fromId, String toId, {bool avoidStairs = false}) {
    final from = nodeById(fromId);
    final to = nodeById(toId);
    if (from == null || to == null) return null;
    if (fromId == toId) {
      return SheetRoute(length: 0, points: [SheetPoint(from.x, from.y)]);
    }
    final fromDoors = _entriesByRoom[fromId] ?? const <SheetEntry>[];
    final toDoors = _entriesByRoom[toId] ?? const <SheetEntry>[];
    if (fromDoors.isEmpty && toDoors.isEmpty) {
      return _shortestLink(from, to, avoidStairs: avoidStairs);
    }
    return _shortestDoors(
      from,
      to,
      fromDoors,
      toDoors,
      avoidStairs: avoidStairs,
    );
  }

  SheetRoute? _shortestLink(
    SheetNode from,
    SheetNode to, {
    required bool avoidStairs,
  }) {
    final startLink = _links[from.id];
    final endLink = _links[to.id];
    if (startLink == null || endLink == null) return null;
    final start = startLink.vertex;
    final goal = endLink.vertex;
    final dist = <String, double>{start: startLink.length};
    final parent = <String, String>{};
    final camePoints = <String, List<SheetPoint>>{};
    final done = <String>{};
    while (true) {
      String? current;
      var best = double.infinity;
      for (final entry in dist.entries) {
        if (done.contains(entry.key)) continue;
        final score = entry.value + _straightLine(entry.key, goal);
        if (score < best) {
          best = score;
          current = entry.key;
        }
      }
      if (current == null) return null;
      if (current == goal) break;
      done.add(current);
      final traveled = dist[current]!;
      for (final hop in _graph[current] ?? const <_Hop>[]) {
        if (done.contains(hop.to)) continue;
        if (avoidStairs && hop.stairs) continue;
        final score = traveled + hop.length;
        final known = dist[hop.to];
        if (known == null || score < known) {
          dist[hop.to] = score;
          parent[hop.to] = current;
          camePoints[hop.to] = hop.points;
        }
      }
    }
    final goalDistance = dist[goal];
    if (goalDistance == null) return null;
    final line = <SheetPoint>[SheetPoint(from.x, from.y)];
    final pieces = <List<SheetPoint>>[];
    var cursor = goal;
    while (cursor != start) {
      final points = camePoints[cursor];
      final previous = parent[cursor];
      if (points == null || previous == null) return null;
      pieces.add(points);
      cursor = previous;
    }
    for (final points in pieces.reversed) {
      for (final point in points) {
        final last = line.last;
        if (last.x != point.x || last.y != point.y) line.add(point);
      }
    }
    line.add(SheetPoint(to.x, to.y));
    final length = ((goalDistance + endLink.length) * 100).round() / 100;
    return SheetRoute(length: length, points: line);
  }

  SheetRoute? _shortestDoors(
    SheetNode from,
    SheetNode to,
    List<SheetEntry> fromDoors,
    List<SheetEntry> toDoors, {
    required bool avoidStairs,
  }) {
    final dist = <String, double>{};
    final parent = <String, String>{};
    final camePoints = <String, List<SheetPoint>>{};
    final heads = <String, List<SheetPoint>>{};
    if (fromDoors.isEmpty) {
      final link = _links[from.id];
      if (link == null) return null;
      dist[link.vertex] = link.length;
      heads[link.vertex] = [SheetPoint(from.x, from.y)];
    } else {
      for (final door in fromDoors) {
        for (final side in _doorSides(door.x, door.y, avoidStairs)) {
          final known = dist[side.vertex];
          if (known != null && known <= side.cost) continue;
          dist[side.vertex] = side.cost;
          heads[side.vertex] = side.points;
          parent.remove(side.vertex);
          camePoints.remove(side.vertex);
        }
      }
    }
    if (dist.isEmpty) return null;

    final finishes = <String, _DoorFinish>{};
    if (toDoors.isEmpty) {
      final link = _links[to.id];
      if (link == null) return null;
      finishes[link.vertex] = _DoorFinish(link.length, [
        SheetPoint(to.x, to.y),
      ]);
    } else {
      for (final door in toDoors) {
        for (final side in _doorSides(door.x, door.y, avoidStairs)) {
          final reversed = side.points.reversed.toList();
          final known = finishes[side.vertex];
          if (known != null && known.extra <= side.cost) continue;
          finishes[side.vertex] = _DoorFinish(
            side.cost,
            reversed.length <= 1 ? const [] : reversed.sublist(1),
          );
        }
      }
    }
    if (finishes.isEmpty) return null;

    final done = <String>{};
    String? bestVertex;
    _DoorFinish? bestFinish;
    var bestCost = double.infinity;
    while (true) {
      String? current;
      var bestScore = double.infinity;
      for (final entry in dist.entries) {
        if (done.contains(entry.key)) continue;
        final score = entry.value + _goalDistance(entry.key, finishes.keys);
        if (score < bestScore) {
          bestScore = score;
          current = entry.key;
        }
      }
      if (current == null) break;
      final finish = finishes[current];
      if (finish != null) {
        final total = dist[current]! + finish.extra;
        if (total < bestCost) {
          bestCost = total;
          bestVertex = current;
          bestFinish = finish;
        }
      }
      if (bestCost < double.infinity && bestScore >= bestCost) break;
      done.add(current);
      final traveled = dist[current]!;
      for (final hop in _graph[current] ?? const <_Hop>[]) {
        if (done.contains(hop.to)) continue;
        if (avoidStairs && hop.stairs) continue;
        final score = traveled + hop.length;
        final known = dist[hop.to];
        if (known == null || score < known) {
          dist[hop.to] = score;
          parent[hop.to] = current;
          camePoints[hop.to] = hop.points;
        }
      }
    }
    if (bestVertex == null || bestFinish == null) return null;
    final pieces = <List<SheetPoint>>[];
    var cursor = bestVertex;
    while (parent.containsKey(cursor)) {
      final points = camePoints[cursor];
      final previous = parent[cursor];
      if (points == null || previous == null) return null;
      pieces.add(points);
      cursor = previous;
    }
    final head = heads[cursor];
    if (head == null || head.isEmpty) return null;
    final line = <SheetPoint>[...head];
    for (final points in pieces.reversed) {
      for (final point in points) {
        final last = line.last;
        if (last.x != point.x || last.y != point.y) line.add(point);
      }
    }
    for (final point in bestFinish.tail) {
      final last = line.last;
      if (last.x != point.x || last.y != point.y) line.add(point);
    }
    final length = (bestCost * 100).round() / 100;
    return SheetRoute(length: length, points: line);
  }

  List<_DoorSide> _doorSides(double x, double y, bool avoidStairs) {
    var best = double.infinity;
    SheetEdge? edge;
    var segment = 0;
    var join = const SheetPoint(0, 0);
    for (final candidate in edges) {
      if (avoidStairs && candidate.stairs) continue;
      final points = candidate.points;
      for (var i = 1; i < points.length; i++) {
        final hit = _closestOnSegment(x, y, points[i - 1], points[i]);
        if (hit.distance < best) {
          best = hit.distance;
          edge = candidate;
          segment = i - 1;
          join = hit.point;
        }
      }
    }
    if (edge == null || edge.points.isEmpty) return const [];
    final door = SheetPoint(x, y);
    final points = edge.points;
    final towardA = <SheetPoint>[door];
    _pushPoint(towardA, join);
    for (var k = segment; k >= 0; k--) {
      _pushPoint(towardA, points[k]);
    }
    final towardB = <SheetPoint>[door];
    _pushPoint(towardB, join);
    for (var k = segment + 1; k < points.length; k++) {
      _pushPoint(towardB, points[k]);
    }
    return [
      _DoorSide(edge.a, _polylineLength(towardA), towardA),
      _DoorSide(edge.b, _polylineLength(towardB), towardB),
    ];
  }

  double _goalDistance(String vertex, Iterable<String> goals) {
    var best = double.infinity;
    for (final goal in goals) {
      final distance = _straightLine(vertex, goal);
      if (distance < best) best = distance;
    }
    return best == double.infinity ? 0 : best;
  }

  double _straightLine(String fromId, String toId) {
    final from = _positions[fromId];
    final to = _positions[toId];
    if (from == null || to == null) return 0;
    return math.sqrt(math.pow(from.x - to.x, 2) + math.pow(from.y - to.y, 2));
  }
}

class _DoorSide {
  const _DoorSide(this.vertex, this.cost, this.points);

  final String vertex;
  final double cost;
  final List<SheetPoint> points;
}

class _DoorFinish {
  const _DoorFinish(this.extra, this.tail);

  final double extra;
  final List<SheetPoint> tail;
}

({SheetPoint point, double distance}) _closestOnSegment(
  double x,
  double y,
  SheetPoint a,
  SheetPoint b,
) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final length2 = dx * dx + dy * dy;
  final t = length2 < 1e-8
      ? 0.0
      : (((x - a.x) * dx + (y - a.y) * dy) / length2).clamp(0.0, 1.0);
  final point = SheetPoint(a.x + dx * t, a.y + dy * t);
  final offsetX = x - point.x;
  final offsetY = y - point.y;
  return (
    point: point,
    distance: math.sqrt(offsetX * offsetX + offsetY * offsetY),
  );
}

void _pushPoint(List<SheetPoint> line, SheetPoint point) {
  if (line.isNotEmpty) {
    final last = line.last;
    if (last.x == point.x && last.y == point.y) return;
  }
  line.add(point);
}

double _polylineLength(List<SheetPoint> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    final dx = points[i].x - points[i - 1].x;
    final dy = points[i].y - points[i - 1].y;
    length += math.sqrt(dx * dx + dy * dy);
  }
  return length;
}

List<SheetPoint> _points(Object? raw) {
  if (raw is! List) return const [];
  final points = <SheetPoint>[];
  for (final item in raw) {
    if (item is! List || item.length < 2) continue;
    points.add(
      SheetPoint((item[0] as num).toDouble(), (item[1] as num).toDouble()),
    );
  }
  return points;
}

void _remember(
  Map<String, List<_Hop>> graph,
  String from,
  String to,
  double length,
  List<SheetPoint> points,
  bool stairs,
) {
  graph.putIfAbsent(from, () => []).add(_Hop(to, length, points, stairs));
}

bool _stairs(Object? flag, List<SheetPoint> points, List<SheetNode> nodes) {
  if (flag is bool) return flag;
  for (final node in nodes) {
    if (node.kind != 'stairs' && node.kind != 'fire_escape') continue;
    for (final point in points) {
      final dx = point.x - node.x;
      final dy = point.y - node.y;
      if (dx * dx + dy * dy <= 48 * 48) return true;
    }
  }
  return false;
}

Color sheetKindColor(String kind) {
  return switch (kind) {
    'classroom' => const Color(0xFF1D4ED8),
    'toilet' => const Color(0xFF0F766E),
    'canteen' => const Color(0xFFC2410C),
    'kitchen' => const Color(0xFFEA580C),
    'parking' => const Color(0xFF374151),
    'office' => const Color(0xFF7C3AED),
    'gate' => const Color(0xFFB45309),
    'guard_room' => const Color(0xFFA16207),
    'lab' => const Color(0xFF0369A1),
    'store' => const Color(0xFF57534E),
    'hall' => const Color(0xFF4338CA),
    'staff_room' => const Color(0xFF6D28D9),
    'corridor' => const Color(0xFF64748B),
    'lobby' => const Color(0xFF7E22CE),
    'courtyard' => const Color(0xFF15803D),
    'library' => const Color(0xFF1E3A8A),
    'medical' => const Color(0xFFBE123C),
    'stationery' => const Color(0xFF9F1239),
    'room' => const Color(0xFF334155),
    'landmark' => const Color(0xFF0E7490),
    'paved' => const Color(0xFF78716C),
    'playground' => const Color(0xFF166534),
    'stairs' => const Color(0xFF9A3412),
    'deck' => const Color(0xFF115E59),
    'fire_escape' => const Color(0xFFB91C1C),
    _ => const Color(0xFF111827),
  };
}

double sheetBlockHeight(String kind) {
  return switch (kind) {
    'classroom' || 'lab' => 34,
    'office' || 'staff_room' => 30,
    'hall' => 48,
    'lobby' => 58,
    'library' => 42,
    'canteen' => 28,
    'kitchen' => 24,
    'toilet' => 16,
    'stairs' => 14,
    'corridor' => 8,
    'courtyard' => 6,
    'paved' => 4,
    'parking' => 10,
    'gate' => 18,
    'playground' => 8,
    'landmark' => 12,
    'deck' => 10,
    'room' => 20,
    'store' || 'stationery' => 18,
    'medical' => 22,
    'guard_room' => 16,
    'fire_escape' => 20,
    _ => 20,
  };
}

double sheetBlockWidth(String kind) {
  if (kind == 'hall' || kind == 'library') return 34;
  if (kind == 'classroom' || kind == 'lab') return 26;
  return 18;
}
