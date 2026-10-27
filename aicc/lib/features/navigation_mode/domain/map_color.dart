import 'dart:math' as math;
import 'dart:ui';

import 'sheet_map.dart';

const mapGroundColor = Color(0xFF8FCB78);
const mapBuildingColor = Color(0xFFE7D3AE);
const mapPavedColor = Color(0xFFD9DDE3);

const sheetPointsPerFoot = 0.3048 / 0.14;

enum CampusSurface { ground, building, paved }

class RoomSpan {
  const RoomSpan(this.a, this.b);

  final double a;
  final double b;
}

CampusSurface campusSurface(String kind) {
  return switch (kind) {
    'courtyard' || 'playground' || 'landmark' || 'gate' => CampusSurface.ground,
    'paved' || 'corridor' || 'deck' || 'parking' => CampusSurface.paved,
    _ => CampusSurface.building,
  };
}

RoomSpan? parseRoomSpan(Object? raw) {
  if (raw is! String) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;
  final pair = RegExp(
    r"""(\d+(?:\.\d+)?)\s*'\s*(?:-\s*(\d+(?:\.\d+)?)\s*")?\s*[xX×]\s*(\d+(?:\.\d+)?)\s*'\s*(?:-\s*(\d+(?:\.\d+)?)\s*")?""",
  ).firstMatch(text);
  if (pair != null) {
    return RoomSpan(
      _feet(pair.group(1)!, pair.group(2)),
      _feet(pair.group(3)!, pair.group(4)),
    );
  }
  final single = RegExp(
    r"""(\d+(?:\.\d+)?)\s*'\s*(?:-\s*(\d+(?:\.\d+)?)\s*")?""",
  ).firstMatch(text);
  if (single == null) return null;
  final width = _feet(single.group(1)!, single.group(2));
  final depth = text.toLowerCase().contains('wide')
      ? 36 * sheetPointsPerFoot
      : width;
  return RoomSpan(width, depth);
}

class CampusPatch {
  const CampusPatch({
    required this.x,
    required this.y,
    required this.along,
    required this.across,
    required this.angle,
    required this.surface,
  });

  final double x;
  final double y;
  final double along;
  final double across;
  final double angle;
  final CampusSurface surface;
}

List<CampusPatch> campusPatches(GroundSheet sheet) {
  final patches = <CampusPatch>[];
  for (final node in sheet.nodes) {
    final surface = campusSurface(node.kind);
    if (surface == CampusSurface.ground) continue;
    final span = parseRoomSpan(node.size) ?? _fallbackSpan(node.kind);
    final along = math.max(span.a, span.b);
    final across = math.min(span.a, span.b);
    final scale = surface == CampusSurface.building ? 1.16 : 1.0;
    patches.add(
      CampusPatch(
        x: node.x,
        y: node.y,
        along: along * scale,
        across: across * scale,
        angle: _nearestAngle(sheet, node.x, node.y),
        surface: surface,
      ),
    );
  }
  return patches;
}

void paintCampusColors({
  required Canvas canvas,
  required GroundSheet sheet,
  required double imageWidth,
  required double imageHeight,
  required Offset Function(double imageX, double imageY) map,
}) {
  final width = imageWidth;
  final height = imageHeight;
  final ground = Path()
    ..moveTo(map(0, 0).dx, map(0, 0).dy)
    ..lineTo(map(width, 0).dx, map(width, 0).dy)
    ..lineTo(map(width, height).dx, map(width, height).dy)
    ..lineTo(map(0, height).dx, map(0, height).dy)
    ..close();
  canvas.drawPath(ground, Paint()..color = mapGroundColor);

  final patches = campusPatches(sheet);
  for (final patch in patches) {
    if (patch.surface == CampusSurface.building) {
      _drawPatch(canvas, sheet, patch, width, height, map, mapBuildingColor);
    }
  }
  for (final patch in patches) {
    if (patch.surface == CampusSurface.paved) {
      _drawPatch(canvas, sheet, patch, width, height, map, mapPavedColor);
    }
  }
  _drawPavedWays(canvas, sheet, width, height, map);
}

void _drawPatch(
  Canvas canvas,
  GroundSheet sheet,
  CampusPatch patch,
  double imageWidth,
  double imageHeight,
  Offset Function(double imageX, double imageY) map,
  Color color,
) {
  final cosA = math.cos(patch.angle);
  final sinA = math.sin(patch.angle);
  final hx = patch.along / 2;
  final hy = patch.across / 2;
  Offset corner(double along, double across) {
    final x = patch.x + along * cosA - across * sinA;
    final y = patch.y + along * sinA + across * cosA;
    return map(x / sheet.pageWidth * imageWidth, y / sheet.pageHeight * imageHeight);
  }

  final path = Path()
    ..moveTo(corner(-hx, -hy).dx, corner(-hx, -hy).dy)
    ..lineTo(corner(hx, -hy).dx, corner(hx, -hy).dy)
    ..lineTo(corner(hx, hy).dx, corner(hx, hy).dy)
    ..lineTo(corner(-hx, hy).dx, corner(-hx, hy).dy)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _drawPavedWays(
  Canvas canvas,
  GroundSheet sheet,
  double imageWidth,
  double imageHeight,
  Offset Function(double imageX, double imageY) map,
) {
  const half = 15.0;
  final paint = Paint()..color = mapPavedColor;
  for (final edge in sheet.edges) {
    final pixels = [
      for (final point in edge.points)
        Offset(
          point.x / sheet.pageWidth * imageWidth,
          point.y / sheet.pageHeight * imageHeight,
        ),
    ];
    if (pixels.length < 2) continue;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < pixels.length; i++) {
      final before = pixels[i == 0 ? i : i - 1];
      final after = pixels[i == pixels.length - 1 ? i : i + 1];
      var dx = after.dx - before.dx;
      var dy = after.dy - before.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length < 1e-3) continue;
      dx /= length;
      dy /= length;
      final at = pixels[i];
      left.add(map(at.dx - dy * half, at.dy + dx * half));
      right.add(map(at.dx + dy * half, at.dy - dx * half));
    }
    if (left.length < 2 || right.length < 2) continue;
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final point in left.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    for (final point in right.reversed) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

RoomSpan _fallbackSpan(String kind) {
  final (feetA, feetB) = switch (kind) {
    'hall' || 'library' || 'canteen' || 'building' => (48.0, 40.0),
    'parking' => (70.0, 40.0),
    'stairs' || 'fire_escape' => (14.0, 22.0),
    'toilet' || 'store' || 'guard_room' => (12.0, 16.0),
    'corridor' || 'deck' || 'paved' || 'lobby' => (16.0, 36.0),
    _ => (21.0, 24.0),
  };
  return RoomSpan(feetA * sheetPointsPerFoot, feetB * sheetPointsPerFoot);
}

double _nearestAngle(GroundSheet sheet, double x, double y) {
  var best = double.infinity;
  var angle = 0.0;
  for (final edge in sheet.edges) {
    final points = edge.points;
    for (var i = 1; i < points.length; i++) {
      final ax = points[i - 1].x;
      final ay = points[i - 1].y;
      final bx = points[i].x;
      final by = points[i].y;
      final dx = bx - ax;
      final dy = by - ay;
      final length2 = dx * dx + dy * dy;
      if (length2 < 1) continue;
      final t = (((x - ax) * dx + (y - ay) * dy) / length2).clamp(0.0, 1.0);
      final px = ax + dx * t;
      final py = ay + dy * t;
      final distance2 = (x - px) * (x - px) + (y - py) * (y - py);
      if (distance2 < best) {
        best = distance2;
        angle = math.atan2(dy, dx);
      }
    }
  }
  return angle;
}

double _feet(String feet, String? inches) {
  final value =
      double.parse(feet) + (inches == null ? 0 : double.parse(inches) / 12);
  return value * sheetPointsPerFoot;
}
