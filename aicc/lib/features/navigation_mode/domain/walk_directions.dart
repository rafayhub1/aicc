import 'dart:math' as math;

import 'sheet_map.dart';

enum WalkManeuver {
  depart,
  straight,
  slightLeft,
  left,
  sharpLeft,
  uTurnLeft,
  slightRight,
  right,
  sharpRight,
  uTurnRight,
  arrive,
}

class WalkStep {
  const WalkStep({
    required this.maneuver,
    required this.action,
    required this.detail,
    required this.distance,
  });

  final WalkManeuver maneuver;
  final String action;
  final String detail;
  final double distance;

  String get speech => detail.isEmpty ? action : '$action. $detail';
}

String voiceScript(List<WalkStep> steps) {
  final lines = <String>[];
  for (var i = 0; i < steps.length; i++) {
    lines.add('Step ${i + 1}. ${steps[i].speech}');
  }
  return lines.join(' ');
}

List<WalkStep> walkDirections(
  List<SheetPoint> points, {
  required String fromName,
  required String toName,
}) {
  final line = _dedupe(points);
  if (line.length < 2) {
    return [
      WalkStep(
        maneuver: WalkManeuver.arrive,
        action: 'You are already at $fromName',
        detail: '',
        distance: 0,
      ),
    ];
  }

  final corners = _corners(line);
  final marks = <int>[0, ...corners, line.length - 1];
  final steps = <WalkStep>[];
  for (var i = 0; i < marks.length - 1; i++) {
    final from = marks[i];
    final to = marks[i + 1];
    final distance = _span(line, from, to);
    if (from == 0) {
      steps.add(
        WalkStep(
          maneuver: WalkManeuver.depart,
          action: 'Leave $fromName',
          detail: 'Walk ${walkDistance(distance)} along the pathway.',
          distance: distance,
        ),
      );
      continue;
    }
    final maneuver = _maneuver(_angleAt(line, from));
    if (maneuver == WalkManeuver.straight) continue;
    steps.add(
      WalkStep(
        maneuver: maneuver,
        action: _action(maneuver),
        detail: 'Continue for ${walkDistance(distance)}.',
        distance: distance,
      ),
    );
  }
  steps.add(
    WalkStep(
      maneuver: WalkManeuver.arrive,
      action: 'Arrive at $toName',
      detail: 'You have reached your destination.',
      distance: 0,
    ),
  );
  return steps;
}

/// Adjacent 21-by-24-foot classrooms sit about 50 sheet points apart.
const double metersPerSheetPoint = 0.14;

String walkDistance(double points) {
  final meters = points * metersPerSheetPoint;
  if (meters < 6) return 'a few steps';
  final rounded = meters >= 20 ? (meters / 5).round() * 5 : meters.round();
  final unit = rounded == 1 ? 'meter' : 'meters';
  return 'about $rounded $unit';
}

/// Drops the stair-steps of the traced centerline and keeps real corners.
List<SheetPoint> straightenPath(List<SheetPoint> points) {
  if (points.length < 3) return points;
  const tolerance = 14.0;
  final keep = List<bool>.filled(points.length, false);
  keep[0] = true;
  keep[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final range = stack.removeLast();
    var worst = 0.0;
    var index = -1;
    for (var i = range.$1 + 1; i < range.$2; i++) {
      final distance = _distanceToSegment(
        points[range.$1],
        points[range.$2],
        points[i],
      );
      if (distance > worst) {
        worst = distance;
        index = i;
      }
    }
    if (index != -1 && worst > tolerance) {
      keep[index] = true;
      stack.add((range.$1, index));
      stack.add((index, range.$2));
    }
  }
  return [for (var i = 0; i < points.length; i++) if (keep[i]) points[i]];
}

double _distanceToSegment(SheetPoint start, SheetPoint end, SheetPoint point) {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length < 1e-6) return _segment(start, point);
  final cross = dy * point.x - dx * point.y + end.x * start.y - end.y * start.x;
  return cross.abs() / length;
}

List<SheetPoint> _dedupe(List<SheetPoint> points) {
  final line = <SheetPoint>[];
  for (final point in points) {
    if (line.isEmpty || _segment(line.last, point) > 0.5) line.add(point);
  }
  return line;
}

List<int> _corners(List<SheetPoint> line) {
  const minimumTurn = 28.0;
  const cluster = 48.0;
  final found = <({int index, double angle})>[];
  for (var i = 1; i < line.length - 1; i++) {
    final angle = _angleAt(line, i);
    if (angle.abs() < minimumTurn) continue;
    if (found.isEmpty || _span(line, found.last.index, i) > cluster) {
      found.add((index: i, angle: angle));
    } else if (angle.abs() > found.last.angle.abs()) {
      found[found.length - 1] = (index: i, angle: angle);
    }
  }
  return [for (final corner in found) corner.index];
}

double _angleAt(List<SheetPoint> line, int index) {
  final incoming = _offset(line, index, 42, -1);
  final outgoing = _offset(line, index, 42, 1);
  if (incoming == null || outgoing == null) return 0;
  return _turnDegrees(incoming.$1, incoming.$2, outgoing.$1, outgoing.$2);
}

(double, double)? _offset(
  List<SheetPoint> line,
  int index,
  double distance,
  int direction,
) {
  var remaining = distance;
  var cursor = index;
  final origin = line[index];
  while (remaining > 0) {
    final next = cursor + direction;
    if (next < 0 || next >= line.length) {
      if (cursor == index) return null;
      final end = line[cursor];
      final traveled = _segment(origin, end);
      if (traveled < 12) return null;
      return direction > 0
          ? (end.x - origin.x, end.y - origin.y)
          : (origin.x - end.x, origin.y - end.y);
    }
    final start = line[cursor];
    final end = line[next];
    final length = _segment(start, end);
    if (length >= remaining) {
      final t = remaining / length;
      final x = start.x + (end.x - start.x) * t;
      final y = start.y + (end.y - start.y) * t;
      return direction > 0 ? (x - origin.x, y - origin.y) : (origin.x - x, origin.y - y);
    }
    remaining -= length;
    cursor = next;
  }
  return null;
}

double _turnDegrees(double vx, double vy, double wx, double wy) {
  final cross = wx * vy - wy * vx;
  final dot = vx * wx + vy * wy;
  return math.atan2(cross, dot) * 180 / math.pi;
}

WalkManeuver _maneuver(double degrees) {
  final left = degrees > 0;
  final magnitude = degrees.abs();
  if (magnitude < 28) return WalkManeuver.straight;
  if (magnitude < 50) {
    return left ? WalkManeuver.slightLeft : WalkManeuver.slightRight;
  }
  if (magnitude < 120) return left ? WalkManeuver.left : WalkManeuver.right;
  if (magnitude < 160) {
    return left ? WalkManeuver.sharpLeft : WalkManeuver.sharpRight;
  }
  return left ? WalkManeuver.uTurnLeft : WalkManeuver.uTurnRight;
}

String _action(WalkManeuver maneuver) {
  return switch (maneuver) {
    WalkManeuver.slightLeft => 'Bear left',
    WalkManeuver.left => 'Turn left',
    WalkManeuver.sharpLeft => 'Make a sharp left',
    WalkManeuver.uTurnLeft => 'Make a U-turn to the left',
    WalkManeuver.slightRight => 'Bear right',
    WalkManeuver.right => 'Turn right',
    WalkManeuver.sharpRight => 'Make a sharp right',
    WalkManeuver.uTurnRight => 'Make a U-turn to the right',
    WalkManeuver.straight => 'Continue straight',
    WalkManeuver.depart => 'Leave',
    WalkManeuver.arrive => 'Arrive',
  };
}

double _span(List<SheetPoint> line, int from, int to) {
  var total = 0.0;
  final start = math.min(from, to);
  final end = math.max(from, to);
  for (var i = start; i < end; i++) {
    total += _segment(line[i], line[i + 1]);
  }
  return total;
}

double _segment(SheetPoint a, SheetPoint b) {
  return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}
