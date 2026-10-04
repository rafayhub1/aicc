import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class CampusPlace {
  const CampusPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.rect,
    required this.hub,
    required this.color,
  });

  final String id;
  final String name;
  final String category;
  final Rect rect;
  final String hub;
  final Color color;

  Offset get center => rect.center;
}

const walkwayHubs = <String, Offset>{
  'gate': Offset(500, 700),
  'south': Offset(500, 540),
  'central': Offset(500, 380),
  'north': Offset(500, 200),
  'west': Offset(250, 380),
  'east': Offset(750, 380),
};

const walkwayEdges = <List<String>>[
  ['gate', 'south'],
  ['south', 'central'],
  ['central', 'north'],
  ['west', 'central'],
  ['central', 'east'],
];

const campusPlaces = <CampusPlace>[
  CampusPlace(
    id: 'gate',
    name: 'Main Gate',
    category: 'Entry',
    rect: Rect.fromLTWH(430, 720, 140, 60),
    hub: 'gate',
    color: AppColors.muted,
  ),
  CampusPlace(
    id: 'admin',
    name: 'Admin Block',
    category: 'Admin',
    rect: Rect.fromLTWH(410, 40, 180, 100),
    hub: 'north',
    color: AppColors.primaryLight,
  ),
  CampusPlace(
    id: 'auditorium',
    name: 'Auditorium',
    category: 'Student life',
    rect: Rect.fromLTWH(180, 50, 170, 90),
    hub: 'north',
    color: AppColors.accent,
  ),
  CampusPlace(
    id: 'student',
    name: 'Student Center',
    category: 'Student life',
    rect: Rect.fromLTWH(650, 50, 180, 90),
    hub: 'north',
    color: AppColors.accent,
  ),
  CampusPlace(
    id: 'cs',
    name: 'CS Block',
    category: 'Academic',
    rect: Rect.fromLTWH(40, 250, 180, 120),
    hub: 'west',
    color: AppColors.primary,
  ),
  CampusPlace(
    id: 'psy',
    name: 'Psychology Block',
    category: 'Academic',
    rect: Rect.fromLTWH(40, 470, 180, 110),
    hub: 'west',
    color: AppColors.primary,
  ),
  CampusPlace(
    id: 'bba',
    name: 'BBA Block',
    category: 'Academic',
    rect: Rect.fromLTWH(780, 250, 180, 120),
    hub: 'east',
    color: AppColors.primary,
  ),
  CampusPlace(
    id: 'library',
    name: 'Central Library',
    category: 'Academic',
    rect: Rect.fromLTWH(780, 460, 180, 110),
    hub: 'east',
    color: AppColors.primary,
  ),
  CampusPlace(
    id: 'cafe',
    name: 'Cafeteria',
    category: 'Student life',
    rect: Rect.fromLTWH(640, 590, 160, 80),
    hub: 'south',
    color: AppColors.accent,
  ),
  CampusPlace(
    id: 'sports',
    name: 'Sports Complex',
    category: 'Student life',
    rect: Rect.fromLTWH(40, 640, 200, 90),
    hub: 'gate',
    color: AppColors.accent,
  ),
];

CampusPlace? placeById(String? id) {
  for (final place in campusPlaces) {
    if (place.id == id) return place;
  }
  return null;
}

List<Offset> campusRoute(String fromId, String toId) {
  final from = placeById(fromId);
  final to = placeById(toId);
  if (from == null || to == null || from.id == to.id) return const [];
  final hubs = _hubPath(from.hub, to.hub);
  if (hubs.isEmpty) return const [];
  return [
    from.center,
    for (final hub in hubs) walkwayHubs[hub]!,
    to.center,
  ];
}

List<String> _hubPath(String start, String end) {
  if (start == end) return [start];
  final neighbors = <String, List<String>>{};
  for (final edge in walkwayEdges) {
    neighbors.putIfAbsent(edge[0], () => []).add(edge[1]);
    neighbors.putIfAbsent(edge[1], () => []).add(edge[0]);
  }
  final queue = <String>[start];
  final previous = <String, String>{start: start};
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (current == end) break;
    for (final next in neighbors[current] ?? const <String>[]) {
      if (previous.containsKey(next)) continue;
      previous[next] = current;
      queue.add(next);
    }
  }
  if (!previous.containsKey(end)) return const [];
  final path = <String>[end];
  var cursor = end;
  while (cursor != start) {
    cursor = previous[cursor]!;
    path.add(cursor);
  }
  return path.reversed.toList();
}

class CampusMapPainter extends CustomPainter {
  CampusMapPainter({
    required this.route,
    required this.dashPhase,
    this.fromId,
    this.toId,
  });

  final List<Offset> route;
  final double dashPhase;
  final String? fromId;
  final String? toId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      Paint()..color = const Color(0xFFF7F4EE),
    );
    final grass = Paint()..color = const Color(0xFFDCEBDD);
    canvas.drawOval(const Rect.fromLTWH(80, 160, 120, 70), grass);
    canvas.drawOval(const Rect.fromLTWH(800, 160, 120, 70), grass);
    canvas.drawOval(const Rect.fromLTWH(300, 600, 140, 60), grass);

    final walkway = Paint()
      ..color = const Color(0xFFD5DDE6)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;
    for (final edge in walkwayEdges) {
      canvas.drawLine(walkwayHubs[edge[0]]!, walkwayHubs[edge[1]]!, walkway);
    }

    for (final place in campusPlaces) {
      final selected = place.id == fromId || place.id == toId;
      final rect = RRect.fromRectAndRadius(place.rect, const Radius.circular(16));
      canvas.drawRRect(rect, Paint()..color = place.color.withValues(alpha: 0.9));
      if (selected) {
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const Color(0xFFF4C95D),
        );
      }
      _label(canvas, place.name, place.rect);
    }

    if (route.length >= 2) {
      final path = Path()..moveTo(route.first.dx, route.first.dy);
      for (final point in route.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      _drawDashed(canvas, path);
      _pin(canvas, route.first, AppColors.primary);
      _pin(canvas, route.last, AppColors.accent);
    }
  }

  void _label(Canvas canvas, String text, Rect rect) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: rect.width - 12);
    painter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - painter.width) / 2,
        rect.top + (rect.height - painter.height) / 2,
      ),
    );
  }

  void _drawDashed(Canvas canvas, Path path) {
    final paint = Paint()
      ..color = const Color(0xFF0B3D66)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var distance = -dashPhase;
      while (distance < metric.length) {
        final start = math.max(0, distance).toDouble();
        final end = math.min(metric.length, distance + 14);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += 24;
      }
    }
  }

  void _pin(Canvas canvas, Offset point, Color color) {
    canvas.drawCircle(point, 9, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(point, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CampusMapPainter oldDelegate) {
    return oldDelegate.dashPhase != dashPhase ||
        oldDelegate.fromId != fromId ||
        oldDelegate.toId != toId ||
        oldDelegate.route.length != route.length;
  }
}
