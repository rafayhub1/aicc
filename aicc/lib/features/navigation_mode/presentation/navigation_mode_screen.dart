import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/theme.dart';
import '../../../widgets/map_control_rail.dart';
import '../domain/map_color.dart';
import '../domain/sheet_map.dart';
import '../domain/walk_directions.dart';

enum SheetProjection { flat, tilted, solid }

double wrapDegrees(double degrees) {
  final turns = (degrees + 180) / 360;
  var wrapped = (turns - turns.floorToDouble()) * 360 - 180;
  if (wrapped >= 180) wrapped = -180;
  return wrapped;
}

double blockHeightFor(String kind, SheetProjection projection) {
  final height = sheetBlockHeight(kind);
  if (projection == SheetProjection.solid) return height * 3.4;
  return height;
}

Offset projectFloorPoint({
  required double px,
  required double py,
  required double z,
  required double imageWidth,
  required double imageHeight,
  required SheetProjection projection,
  required double yaw,
  required double pitch,
  required double scale,
  required double panX,
  required double panY,
}) {
  final x = px - imageWidth / 2;
  final y = py - imageHeight / 2;
  if (projection == SheetProjection.flat) {
    return Offset(x * scale + panX, y * scale + panY);
  }
  final cosY = math.cos(yaw);
  final sinY = math.sin(yaw);
  final xr = x * cosY - y * sinY;
  final yr = x * sinY + y * cosY;
  final y2 = yr * math.cos(pitch) - z * math.sin(pitch);
  if (projection != SheetProjection.solid) {
    return Offset(xr * scale + panX, y2 * scale + panY);
  }
  final z2 = yr * math.sin(pitch) + z * math.cos(pitch);
  final span = math.sqrt(imageWidth * imageWidth + imageHeight * imageHeight);
  final camera = span * 1.15;
  final depth = math.max(camera - z2, camera * 0.12);
  final factor = camera / depth * scale;
  return Offset(xr * factor + panX, y2 * factor + panY);
}

double floorDepth({
  required double px,
  required double py,
  required double z,
  required double imageWidth,
  required double imageHeight,
  required double yaw,
  required double pitch,
}) {
  final x = px - imageWidth / 2;
  final y = py - imageHeight / 2;
  final yr = x * math.sin(yaw) + y * math.cos(yaw);
  return yr * math.sin(pitch) + z * math.cos(pitch);
}

class NavigationModeScreen extends StatefulWidget {
  const NavigationModeScreen({super.key});

  @override
  State<NavigationModeScreen> createState() => _NavigationModeScreenState();
}

class _NavigationModeScreenState extends State<NavigationModeScreen>
    with SingleTickerProviderStateMixin {
  GroundSheet? _sheet;
  ui.Image? _floor;
  Object? _error;
  SheetProjection _projection = SheetProjection.flat;
  bool _accessible = false;
  bool? _showNodesOverride;
  bool _showNetwork = false;
  bool _showColor = true;
  double _yaw = -28 * math.pi / 180;
  double _pitch = 52 * math.pi / 180;
  double _scale = 1;
  double _panX = 0;
  double _panY = 0;
  bool _fitted = false;
  bool _fitQueued = false;
  Size? _fittedSize;
  SheetProjection? _fittedProjection;
  String? _fromId;
  String? _toId;
  String? _selectedId;
  bool _moved = false;
  double _originScale = 1;
  double _originPanX = 0;
  double _originPanY = 0;
  double _originYaw = 0;
  double _originPitch = 0;
  Offset _originFocal = Offset.zero;
  int _pointers = 0;
  bool _orbiting = false;
  late final Ticker _flingTicker;
  Offset _flingVelocity = Offset.zero;
  Duration _flingClock = Duration.zero;
  final ValueNotifier<bool> _speaking = ValueNotifier(false);
  FlutterTts? _tts;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _flingTicker = createTicker(_stepFling);
    _load();
  }

  @override
  void dispose() {
    _closed = true;
    _flingTicker.dispose();
    _floor?.dispose();
    _tts?.stop();
    _speaking.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sheet = await GroundSheet.load();
      if (!mounted) return;
      setState(() => _sheet = sheet);
      final data = await rootBundle.load(GroundSheet.floorAsset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _floor = frame.image;
        _fitted = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _scheduleFit(Size size) {
    if (_sheet == null || _floor == null) return;
    if (_fitted && _fittedSize == size && _fittedProjection == _projection) {
      return;
    }
    if (_fitQueued) return;
    _fitQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitQueued = false;
      if (!mounted || _floor == null) return;
      _fit(size);
    });
  }

  void _stopFling() {
    if (_flingTicker.isActive) _flingTicker.stop();
    _flingVelocity = Offset.zero;
  }

  void _stepFling(Duration elapsed) {
    final dt = (elapsed - _flingClock).inMicroseconds / 1000000;
    _flingClock = elapsed;
    if (dt <= 0) return;
    final step = math.min(dt, 0.032);
    final remaining = _flingVelocity * math.exp(-2.4 * step);
    setState(() {
      _panX += _flingVelocity.dx * step;
      _panY += _flingVelocity.dy * step;
      _flingVelocity = remaining;
    });
    if (_flingVelocity.distance < 40) _stopFling();
  }

  void _zoomAt(Offset local, double factor) {
    _stopFling();
    final next = (_scale * factor).clamp(0.08, 14.0);
    final applied = next / _scale;
    setState(() {
      _panX = local.dx - (local.dx - _panX) * applied;
      _panY = local.dy - (local.dy - _panY) * applied;
      _scale = next;
    });
  }

  void _fit(Size size) {
    final image = _floor;
    if (image == null || size.width <= 0 || size.height <= 0) return;
    _stopFling();
    _scale = 1;
    _panX = 0;
    _panY = 0;
    final corners = [
      Offset.zero,
      Offset(image.width.toDouble(), 0),
      Offset(image.width.toDouble(), image.height.toDouble()),
      Offset(0, image.height.toDouble()),
    ];
    final projected = [
      for (final corner in corners) _project(corner.dx, corner.dy, 0),
    ];
    final minX = projected.map((p) => p.dx).reduce(math.min);
    final maxX = projected.map((p) => p.dx).reduce(math.max);
    final minY = projected.map((p) => p.dy).reduce(math.min);
    final maxY = projected.map((p) => p.dy).reduce(math.max);
    final width = math.max(1.0, maxX - minX);
    final height = math.max(1.0, maxY - minY);
    final padding = _projection == SheetProjection.solid ? 0.0 : 32.0;
    _scale = math.min(
      (size.width - padding) / width,
      (size.height - padding) / height,
    );
    if (_projection == SheetProjection.solid) _scale *= 1.85;
    final fitted = [
      for (final corner in corners) _project(corner.dx, corner.dy, 0),
    ];
    final left = fitted.map((p) => p.dx).reduce(math.min);
    final right = fitted.map((p) => p.dx).reduce(math.max);
    final top = fitted.map((p) => p.dy).reduce(math.min);
    final bottom = fitted.map((p) => p.dy).reduce(math.max);
    setState(() {
      _panX = size.width / 2 - (left + right) / 2;
      _panY = size.height / 2 - (top + bottom) / 2;
      _fitted = true;
      _fittedSize = size;
      _fittedProjection = _projection;
    });
  }

  Offset _toPixel(SheetNode node) {
    final image = _floor!;
    final sheet = _sheet!;
    return Offset(
      node.x / sheet.pageWidth * image.width,
      node.y / sheet.pageHeight * image.height,
    );
  }

  Offset _project(double px, double py, double z) {
    final image = _floor!;
    return projectFloorPoint(
      px: px,
      py: py,
      z: z,
      imageWidth: image.width.toDouble(),
      imageHeight: image.height.toDouble(),
      projection: _projection,
      yaw: _yaw,
      pitch: _pitch,
      scale: _scale,
      panX: _panX,
      panY: _panY,
    );
  }

  SheetNode? _nodeAt(Offset local) {
    final sheet = _sheet;
    if (sheet == null || _floor == null) return null;
    SheetNode? best;
    var bestDistance = double.infinity;
    for (final node in sheet.nodes) {
      final pixel = _toPixel(node);
      final Offset center;
      var radius = 16.0;
      if (_projection == SheetProjection.flat) {
        center = _project(pixel.dx, pixel.dy, 0);
        radius = math.max(16, 9 * _scale);
      } else {
        final width = sheetBlockWidth(node.kind);
        final depth = width * 0.72;
        final height = blockHeightFor(node.kind, _projection);
        final top = [
          _project(pixel.dx - width / 2, pixel.dy - depth / 2, height),
          _project(pixel.dx + width / 2, pixel.dy - depth / 2, height),
          _project(pixel.dx + width / 2, pixel.dy + depth / 2, height),
          _project(pixel.dx - width / 2, pixel.dy + depth / 2, height),
        ];
        center = Offset(
          top.map((point) => point.dx).reduce((a, b) => a + b) / 4,
          top.map((point) => point.dy).reduce((a, b) => a + b) / 4,
        );
        radius = 14;
        for (final point in top) {
          radius = math.max(radius, (point - center).distance + 4);
        }
      }
      final distance = (center - local).distance;
      if (distance <= radius && distance < bestDistance) {
        bestDistance = distance;
        best = node;
      }
    }
    return best;
  }

  void _choose(SheetNode node) {
    _stopVoice();
    setState(() {
      _selectedId = node.id;
      if (_fromId == null || _toId != null) {
        _fromId = node.id;
        _toId = null;
      } else if (node.id != _fromId) {
        _toId = node.id;
      }
    });
  }

  Future<void> _pickPlace({required bool origin}) async {
    final sheet = _sheet;
    if (sheet == null) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => _PlacePickerDialog(
        title: origin ? 'Current location' : 'Destination',
        nodes: sheet.nodes,
        selectedId: origin ? _fromId : _toId,
      ),
    );
    if (picked == null || !mounted) return;
    _stopVoice();
    setState(() {
      _selectedId = picked;
      if (origin) {
        _fromId = picked;
        if (_toId == picked) _toId = null;
      } else {
        _toId = picked;
        if (_fromId == picked) _fromId = null;
      }
    });
  }

  Widget _placeField({
    required Key key,
    required String label,
    required SheetNode? node,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    final sheet = _sheet;
    final text = node == null || sheet == null
        ? 'Select'
        : placeLabel(node, sheet.nodes);
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(color: palette.line),
      ),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: _sheet == null ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.muted.copyWith(fontSize: 11),
                    ),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: node == null ? palette.muted : palette.ink,
                        fontWeight: node == null
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }

  void _clearRoute() {
    _stopVoice();
    setState(() {
      _fromId = null;
      _toId = null;
      _selectedId = null;
    });
  }

  List<WalkStep>? _currentSteps() {
    final sheet = _sheet;
    final from = sheet?.nodeById(_fromId ?? '');
    final to = sheet?.nodeById(_toId ?? '');
    if (sheet == null || from == null || to == null) return null;
    final route = _walk(sheet, from.id, to.id);
    if (route == null) return null;
    return walkDirections(
      straightenPath(route.points),
      fromName: placeLabel(from, sheet.nodes),
      toName: placeLabel(to, sheet.nodes),
    );
  }

  Future<void> _toggleVoice() async {
    if (_speaking.value) {
      await _stopVoice();
      return;
    }
    final steps = _currentSteps();
    if (steps == null || steps.isEmpty) return;
    await _playVoice(steps);
  }

  Future<void> _playVoice(List<WalkStep> steps) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.46);
      await tts.setVolume(1);
      if (_closed) return;
      _speaking.value = true;
      await tts.stop();
      await tts.speak(voiceScript(steps));
    } catch (_) {
      // This device has no speech engine available.
    } finally {
      if (!_closed) _speaking.value = false;
    }
  }

  Future<void> _stopVoice() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // Stopping speech is optional when the engine is unavailable.
    }
    if (!_closed) _speaking.value = false;
  }

  Future<void> _openDirections() async {
    final sheet = _sheet;
    final from = sheet?.nodeById(_fromId ?? '');
    final to = sheet?.nodeById(_toId ?? '');
    final steps = _currentSteps();
    final route = from != null && to != null
        ? _walk(sheet, from.id, to.id)
        : null;
    if (sheet == null ||
        from == null ||
        to == null ||
        steps == null ||
        route == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _DirectionsSheet(
          title:
              '${placeLabel(from, sheet.nodes)} to ${placeLabel(to, sheet.nodes)}',
          summary: '${steps.length} steps · ${walkDistance(route.length)}',
          steps: steps,
          speaking: _speaking,
          onVoice: _toggleVoice,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Mode'),
        actions: [
          IconButton(
            tooltip: 'Reset view',
            onPressed: _floor == null || _fittedSize == null
                ? null
                : () => _fit(_fittedSize!),
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<SheetProjection>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: SheetProjection.flat,
                  label: Text('2D'),
                  icon: Icon(Icons.map_outlined),
                ),
                ButtonSegment(
                  value: SheetProjection.tilted,
                  label: Text('2.5D'),
                  icon: Icon(Icons.layers_outlined),
                ),
                ButtonSegment(
                  value: SheetProjection.solid,
                  label: Text('3D'),
                  icon: Icon(Icons.threed_rotation),
                ),
              ],
              selected: {_projection},
              onSelectionChanged: (next) {
                setState(() {
                  _projection = next.first;
                  _fitted = false;
                  if (_projection == SheetProjection.tilted) {
                    _yaw = (wrapDegrees(_yaw * 180 / math.pi) * math.pi / 180)
                        .clamp(-80 * math.pi / 180, 80 * math.pi / 180);
                    _pitch = _pitch.clamp(
                      20 * math.pi / 180,
                      75 * math.pi / 180,
                    );
                  }
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _placeField(
                    key: const Key('nav-from'),
                    label: 'Current location',
                    node: _sheet?.nodeById(_fromId ?? ''),
                    onTap: () => _pickPlace(origin: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _placeField(
                    key: const Key('nav-to'),
                    label: 'Destination',
                    node: _sheet?.nodeById(_toId ?? ''),
                    onTap: () => _pickPlace(origin: false),
                  ),
                ),
              ],
            ),
          ),
          if (_projection != SheetProjection.flat) _orbitBars(),
          Expanded(child: _stage()),
          _status(palette),
        ],
      ),
    );
  }

  Widget _orbitBars() {
    final solid = _projection == SheetProjection.solid;
    final tiltMin = solid ? 2.0 : 20.0;
    final tiltMax = solid ? 88.0 : 75.0;
    final turnMin = solid ? -180.0 : -80.0;
    final turnMax = solid ? 180.0 : 80.0;
    final tilt = (_pitch * 180 / math.pi).clamp(tiltMin, tiltMax);
    final turn = (solid
            ? wrapDegrees(_yaw * 180 / math.pi)
            : _yaw * 180 / math.pi)
        .clamp(turnMin, turnMax);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text('Tilt', style: AppTextStyles.label),
          Expanded(
            child: Slider(
              key: const Key('nav-tilt'),
              min: tiltMin,
              max: tiltMax,
              value: tilt,
              onChanged: (value) {
                setState(() => _pitch = value * math.pi / 180);
              },
            ),
          ),
          Text('Turn', style: AppTextStyles.label),
          Expanded(
            child: Slider(
              key: const Key('nav-turn'),
              min: turnMin,
              max: turnMax,
              value: turn,
              onChanged: (value) {
                setState(() => _yaw = value * math.pi / 180);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _rememberGesture(Offset focal) {
    _stopFling();
    _moved = false;
    _orbiting = false;
    _originScale = _scale;
    _originPanX = _panX;
    _originPanY = _panY;
    _originYaw = _yaw;
    _originPitch = _pitch;
    _originFocal = focal;
  }

  Widget _stage() {
    if (_error != null) {
      return Center(child: Text('The ground floor could not be opened.'));
    }
    final sheet = _sheet;
    final floor = _floor;
    if (sheet == null || floor == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _scheduleFit(size);
        return Stack(
          children: [
            Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _zoomAt(
                event.localPosition,
                event.scrollDelta.dy < 0 ? 1.12 : 1 / 1.12,
              );
            } else if (event is PointerScaleEvent) {
              _zoomAt(event.localPosition, event.scale);
            }
          },
          onPointerPanZoomStart: (event) {
            _rememberGesture(event.localPosition);
            _moved = true;
          },
          onPointerPanZoomUpdate: (event) {
            final next = (_originScale * event.scale).clamp(0.08, 14.0);
            final worldX = (_originFocal.dx - _originPanX) / _originScale;
            final worldY = (_originFocal.dy - _originPanY) / _originScale;
            final focal = _originFocal + event.localPan;
            setState(() {
              _scale = next;
              _panX = focal.dx - worldX * next;
              _panY = focal.dy - worldY * next;
            });
          },
          child: GestureDetector(
            key: const Key('nav-map'),
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              _rememberGesture(details.localFocalPoint);
              _pointers = details.pointerCount;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount != _pointers) {
                _rememberGesture(details.localFocalPoint);
                _pointers = details.pointerCount;
              }
              final focal = details.localFocalPoint;
              final delta = focal - _originFocal;
              if (_projection == SheetProjection.solid &&
                  details.pointerCount < 2) {
                if (delta.distance > 6) {
                  _moved = true;
                  _orbiting = true;
                }
                setState(() {
                  _yaw = _originYaw - delta.dx * 0.012;
                  _pitch = (_originPitch + delta.dy * 0.008).clamp(
                    2 * math.pi / 180,
                    88 * math.pi / 180,
                  );
                });
                return;
              }
              if (delta.distance > 6 || (details.scale - 1).abs() > 0.02) {
                _moved = true;
              }
              final next = (_originScale * details.scale).clamp(0.08, 14.0);
              final worldX = (_originFocal.dx - _originPanX) / _originScale;
              final worldY = (_originFocal.dy - _originPanY) / _originScale;
              setState(() {
                _scale = next;
                _panX = focal.dx - worldX * next;
                _panY = focal.dy - worldY * next;
              });
            },
            onScaleEnd: (details) {
              if (_orbiting) {
                _orbiting = false;
                return;
              }
              final velocity = details.velocity.pixelsPerSecond;
              if (!_moved || velocity.distance < 180) return;
              _flingVelocity = velocity;
              _flingClock = Duration.zero;
              _flingTicker.start();
            },
            onTapUp: (details) {
              if (_moved) return;
              final node = _nodeAt(details.localPosition);
              if (node != null) _choose(node);
            },
            child: CustomPaint(
              painter: _SheetPainter(
                sheet: sheet,
                floor: floor,
                projection: _projection,
                yaw: _yaw,
                pitch: _pitch,
                scale: _scale,
                panX: _panX,
                panY: _panY,
                route: _fromId != null && _toId != null
                    ? _walk(sheet, _fromId!, _toId!)
                    : null,
                fromId: _fromId,
                toId: _toId,
                selectedId: _selectedId,
                showNodes: _nodesVisible,
                showNetwork: _showNetwork,
                avoidStairs: _accessible,
                showColor: _showColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
            ),
            Positioned(
              right: 10,
              top: 8,
              child: MapControlRail(
                onRecenter: () => _fit(size),
                onZoomIn: () => _zoomAt(
                  Offset(size.width / 2, size.height / 2),
                  1.25,
                ),
                onZoomOut: () => _zoomAt(
                  Offset(size.width / 2, size.height / 2),
                  1 / 1.25,
                ),
                accessible: _accessible,
                onAccessible: () => setState(() => _accessible = !_accessible),
                layers: [
                  MapLayerChoice(
                    id: 'flat',
                    label: '2D',
                    selected: _projection == SheetProjection.flat,
                  ),
                  MapLayerChoice(
                    id: 'tilted',
                    label: '2.5D',
                    selected: _projection == SheetProjection.tilted,
                  ),
                  MapLayerChoice(
                    id: 'solid',
                    label: '3D',
                    selected: _projection == SheetProjection.solid,
                  ),
                  MapLayerChoice(
                    id: 'nodes',
                    label: 'Nodes',
                    selected: _nodesVisible,
                  ),
                  MapLayerChoice(
                    id: 'paths',
                    label: 'Pathways',
                    selected: _showNetwork,
                  ),
                  MapLayerChoice(
                    id: 'color',
                    label: 'Color',
                    selected: _showColor,
                  ),
                ],
                onLayer: _chooseLayer,
              ),
            ),
          ],
        );
      },
    );
  }

  bool get _nodesVisible =>
      _showNodesOverride ?? _projection == SheetProjection.solid;

  SheetRoute? _walk(GroundSheet? sheet, String fromId, String toId) {
    return sheet?.shortest(fromId, toId, avoidStairs: _accessible);
  }

  void _chooseLayer(String id) {
    setState(() {
      final next = switch (id) {
        'flat' => SheetProjection.flat,
        'tilted' => SheetProjection.tilted,
        'solid' => SheetProjection.solid,
        _ => null,
      };
      if (next != null) {
        _projection = next;
        _fitted = false;
        if (_projection == SheetProjection.tilted) {
          _yaw = (wrapDegrees(_yaw * 180 / math.pi) * math.pi / 180).clamp(
            -80 * math.pi / 180,
            80 * math.pi / 180,
          );
          _pitch = _pitch.clamp(20 * math.pi / 180, 75 * math.pi / 180);
        }
        return;
      }
      if (id == 'nodes') {
        _showNodesOverride = !_nodesVisible;
      } else if (id == 'paths') {
        _showNetwork = !_showNetwork;
      } else if (id == 'color') {
        _showColor = !_showColor;
      }
    });
  }

  Widget _status(AppPalette palette) {
    final sheet = _sheet;
    final from = sheet?.nodeById(_fromId ?? '');
    final to = sheet?.nodeById(_toId ?? '');
    final route = from != null && to != null
        ? _walk(sheet, from.id, to.id)
        : null;
    final detail = from == null
        ? 'Choose where you are and where you want to go.'
        : to == null
        ? 'From ${placeLabel(from, sheet!.nodes)}. Choose a destination.'
        : '${placeLabel(from, sheet!.nodes)} to ${placeLabel(to, sheet.nodes)}';
    final routeText = from == null || to == null
        ? 'The shortest path appears after both places are selected.'
        : route == null
        ? (_accessible
              ? 'No step-free path between these places.'
              : 'These places are not on the same pathway.')
        : _accessible
        ? 'Step-free path · ${walkDistance(route.length)}'
        : 'Shortest path · ${walkDistance(route.length)}';
    return Material(
      color: palette.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail, style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      Text(
                        routeText,
                        key: const Key('nav-route'),
                        style: AppTextStyles.body.copyWith(color: palette.muted),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: _clearRoute, child: const Text('Clear')),
              ],
            ),
            if (route != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('nav-directions'),
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _speaking,
                      builder: (context, speaking, _) {
                        return OutlinedButton.icon(
                          key: const Key('nav-voice'),
                          onPressed: _toggleVoice,
                          icon: Icon(
                            speaking
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                          ),
                          label: Text(speaking ? 'Stop' : 'Voice'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  const _SheetPainter({
    required this.sheet,
    required this.floor,
    required this.projection,
    required this.yaw,
    required this.pitch,
    required this.scale,
    required this.panX,
    required this.panY,
    required this.route,
    required this.fromId,
    required this.toId,
    required this.selectedId,
    required this.showNodes,
    required this.showNetwork,
    required this.avoidStairs,
    required this.showColor,
  });

  final GroundSheet sheet;
  final ui.Image floor;
  final SheetProjection projection;
  final double yaw;
  final double pitch;
  final double scale;
  final double panX;
  final double panY;
  final SheetRoute? route;
  final String? fromId;
  final String? toId;
  final String? selectedId;
  final bool showNodes;
  final bool showNetwork;
  final bool avoidStairs;
  final bool showColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD6D3D1));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (projection == SheetProjection.solid) {
      _drawPerspectiveGround(canvas);
    } else {
      _drawGround(canvas);
    }
    if (showNetwork) {
      for (final edge in sheet.edges) {
        if (avoidStairs && edge.stairs) continue;
        _stroke(
          canvas,
          edge.points,
          edge.stairs ? const Color(0xFFB45309) : const Color(0xFF93C5FD),
          projection == SheetProjection.solid ? 10 : 3.5,
          projection == SheetProjection.solid ? 10 : 2,
        );
      }
    }
    final active = route;
    if (active != null) {
      final line = straightenPath(active.points);
      if (projection == SheetProjection.solid) {
        _drawRibbon(canvas, line, 34, 28);
      } else {
        _stroke(canvas, line, const Color(0xFF1D4ED8), 4.5, 6);
      }
    }
    final shown = [
      for (final node in sheet.nodes)
        if (showNodes || node.id == fromId || node.id == toId)
          node,
    ];
    if (projection == SheetProjection.flat) {
      for (final node in shown) {
        _drawMarker(canvas, node);
      }
    } else {
      shown.sort((a, b) => _nodeDepth(a).compareTo(_nodeDepth(b)));
      for (final node in shown) {
        _drawBlock(canvas, node);
      }
    }
    _drawDoors(canvas);
    canvas.restore();
  }

  void _drawGround(Canvas canvas) {
    final tilted = projection == SheetProjection.tilted;
    final cosY = tilted ? math.cos(yaw) : 1.0;
    final sinY = tilted ? math.sin(yaw) : 0.0;
    final cosP = tilted ? math.cos(pitch) : 1.0;
    canvas.save();
    canvas.transform(
      Float64List.fromList([
        cosY * scale,
        sinY * cosP * scale,
        0,
        0,
        -sinY * scale,
        cosY * cosP * scale,
        0,
        0,
        0,
        0,
        1,
        0,
        panX,
        panY,
        0,
        1,
      ]),
    );
    if (showColor) {
      paintCampusColors(
        canvas: canvas,
        sheet: sheet,
        imageWidth: floor.width.toDouble(),
        imageHeight: floor.height.toDouble(),
        map: (x, y) => Offset(x - floor.width / 2, y - floor.height / 2),
      );
    }
    canvas.drawImage(
      floor,
      Offset(-floor.width / 2, -floor.height / 2),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = showColor ? BlendMode.multiply : BlendMode.srcOver,
    );
    canvas.restore();
  }

  void _drawPerspectiveGround(Canvas canvas) {
    const columns = 12;
    const rows = 8;
    final cellWidth = floor.width / columns;
    final cellHeight = floor.height / rows;
    final tiles = <({Rect source, List<Offset> corners, double depth})>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final left = column * cellWidth;
        final top = row * cellHeight;
        final right = left + cellWidth;
        final bottom = top + cellHeight;
        final corners = [
          _project(left, top, 0),
          _project(right, top, 0),
          _project(right, bottom, 0),
          _project(left, bottom, 0),
        ];
        tiles.add((
          source: Rect.fromLTWH(left, top, cellWidth, cellHeight),
          corners: corners,
          depth: _depth(left + cellWidth / 2, top + cellHeight / 2, 0),
        ));
      }
    }
    if (showColor) {
      paintCampusColors(
        canvas: canvas,
        sheet: sheet,
        imageWidth: floor.width.toDouble(),
        imageHeight: floor.height.toDouble(),
        map: (x, y) => _project(x, y, 0),
      );
    }
    tiles.sort((a, b) => a.depth.compareTo(b.depth));
    for (final tile in tiles) {
      final source = tile.source;
      final corner = tile.corners;
      _drawTriangle(
        canvas,
        source,
        source.topLeft,
        source.topRight,
        source.bottomRight,
        corner[0],
        corner[1],
        corner[2],
      );
      _drawTriangle(
        canvas,
        source,
        source.bottomRight,
        source.bottomLeft,
        source.topLeft,
        corner[2],
        corner[3],
        corner[0],
      );
    }
  }

  void _drawTriangle(
    Canvas canvas,
    Rect source,
    Offset s0,
    Offset s1,
    Offset s2,
    Offset d0,
    Offset d1,
    Offset d2,
  ) {
    final matrix = _triangleMatrix(s0, s1, s2, d0, d1, d2);
    if (matrix == null) return;
    canvas.save();
    canvas.clipPath(
      Path()
        ..moveTo(d0.dx, d0.dy)
        ..lineTo(d1.dx, d1.dy)
        ..lineTo(d2.dx, d2.dy)
        ..close(),
    );
    canvas.transform(matrix);
    canvas.drawImageRect(
      floor,
      source,
      source,
      Paint()
        ..filterQuality = FilterQuality.low
        ..blendMode = showColor ? BlendMode.multiply : BlendMode.srcOver,
    );
    canvas.restore();
  }

  Float64List? _triangleMatrix(
    Offset s0,
    Offset s1,
    Offset s2,
    Offset d0,
    Offset d1,
    Offset d2,
  ) {
    final denom =
        s0.dx * (s1.dy - s2.dy) +
        s1.dx * (s2.dy - s0.dy) +
        s2.dx * (s0.dy - s1.dy);
    if (denom.abs() < 1e-4) return null;
    double across(double a, double b, double c) {
      return (a * (s1.dy - s2.dy) + b * (s2.dy - s0.dy) + c * (s0.dy - s1.dy)) /
          denom;
    }

    double down(double a, double b, double c) {
      return (a * (s2.dx - s1.dx) + b * (s0.dx - s2.dx) + c * (s1.dx - s0.dx)) /
          denom;
    }

    final a = across(d0.dx, d1.dx, d2.dx);
    final c = down(d0.dx, d1.dx, d2.dx);
    final b = across(d0.dy, d1.dy, d2.dy);
    final d = down(d0.dy, d1.dy, d2.dy);
    final tx = d0.dx - a * s0.dx - c * s0.dy;
    final ty = d0.dy - b * s0.dx - d * s0.dy;
    return Float64List.fromList([
      a, b, 0, 0, //
      c, d, 0, 0, //
      0, 0, 1, 0, //
      tx, ty, 0, 1,
    ]);
  }

  void _drawRibbon(
    Canvas canvas,
    List<SheetPoint> points,
    double halfWidth,
    double z,
  ) {
    if (points.length < 2) return;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final pixel = _sheetPixel(points[i]);
      final before = _sheetPixel(i == 0 ? points[i] : points[i - 1]);
      final after = _sheetPixel(
        i == points.length - 1 ? points[i] : points[i + 1],
      );
      var dx = after.dx - before.dx;
      var dy = after.dy - before.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length < 1e-3) continue;
      dx /= length;
      dy /= length;
      left.add(_project(pixel.dx - dy * halfWidth, pixel.dy + dx * halfWidth, z));
      right.add(
        _project(pixel.dx + dy * halfWidth, pixel.dy - dx * halfWidth, z),
      );
    }
    if (left.length < 2) return;
    final band = Path()..moveTo(left.first.dx, left.first.dy);
    for (final point in left.skip(1)) {
      band.lineTo(point.dx, point.dy);
    }
    for (final point in right.reversed) {
      band.lineTo(point.dx, point.dy);
    }
    band.close();
    canvas.drawPath(band, Paint()..color = const Color(0xFF1D4ED8));
  }

  void _stroke(
    Canvas canvas,
    List<SheetPoint> points,
    Color color,
    double width,
    double z,
  ) {
    if (points.length < 2) return;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final pixel = _sheetPixel(points[i]);
      final screen = _project(pixel.dx, pixel.dy, z);
      if (i == 0) {
        path.moveTo(screen.dx, screen.dy);
      } else {
        path.lineTo(screen.dx, screen.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDoors(Canvas canvas) {
    for (final entry in sheet.entries) {
      if (entry.room != fromId && entry.room != toId) continue;
      final pixel = _sheetPixel(SheetPoint(entry.x, entry.y));
      final center = _project(
        pixel.dx,
        pixel.dy,
        projection == SheetProjection.solid ? 16 : 0,
      );
      canvas.drawCircle(center, 7, Paint()..color = Colors.white);
      canvas.drawCircle(center, 4.5, Paint()..color = const Color(0xFF0F766E));
    }
  }

  void _drawMarker(Canvas canvas, SheetNode node) {
    final center = _projectNode(node, 0);
    final here = node.id == selectedId || node.id == fromId || node.id == toId;
    final radius = here ? 8.0 : 5.5;
    final color = sheetKindColor(node.kind);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = node.id == toId
            ? const Color(0xFF1D4ED8)
            : node.id == fromId
            ? const Color(0xFF15803D)
            : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(center, radius - 2.2, Paint()..color = color);
    if (here) _label(canvas, node.name, center + const Offset(0, -14));
  }

  void _drawBlock(Canvas canvas, SheetNode node) {
    final pixel = _sheetPixel(SheetPoint(node.x, node.y));
    final width = sheetBlockWidth(node.kind);
    final depth = width * 0.72;
    final height = blockHeightFor(node.kind, projection);
    final corners = [
      Offset(pixel.dx - width / 2, pixel.dy - depth / 2),
      Offset(pixel.dx + width / 2, pixel.dy - depth / 2),
      Offset(pixel.dx + width / 2, pixel.dy + depth / 2),
      Offset(pixel.dx - width / 2, pixel.dy + depth / 2),
    ];
    final ground = [for (final corner in corners) _project(corner.dx, corner.dy, 0)];
    final top = [
      for (final corner in corners) _project(corner.dx, corner.dy, height),
    ];
    final color = sheetKindColor(node.kind);
    for (var i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      final face = Path()
        ..moveTo(ground[i].dx, ground[i].dy)
        ..lineTo(ground[next].dx, ground[next].dy)
        ..lineTo(top[next].dx, top[next].dy)
        ..lineTo(top[i].dx, top[i].dy)
        ..close();
      canvas.drawPath(face, Paint()..color = _shade(color, i.isEven ? 0.78 : 0.62));
    }
    final roof = Path()..moveTo(top.first.dx, top.first.dy);
    for (final point in top.skip(1)) {
      roof.lineTo(point.dx, point.dy);
    }
    roof.close();
    canvas.drawPath(roof, Paint()..color = color);
    final mark = _project(pixel.dx, pixel.dy, height + 8);
    final here = node.id == selectedId || node.id == fromId || node.id == toId;
    canvas.drawCircle(
      mark,
      here ? 7 : 4.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      mark,
      here ? 7 : 4.5,
      Paint()
        ..color = node.id == toId
            ? const Color(0xFF1D4ED8)
            : node.id == fromId
            ? const Color(0xFF15803D)
            : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (here) _label(canvas, node.name, mark + const Offset(0, -12));
  }

  void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF1C1917),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height));
  }

  Offset _projectNode(SheetNode node, double z) {
    final pixel = _sheetPixel(SheetPoint(node.x, node.y));
    return _project(pixel.dx, pixel.dy, z);
  }

  Offset _sheetPixel(SheetPoint point) {
    return Offset(
      point.x / sheet.pageWidth * floor.width,
      point.y / sheet.pageHeight * floor.height,
    );
  }

  double _nodeDepth(SheetNode node) {
    final pixel = _sheetPixel(SheetPoint(node.x, node.y));
    return _depth(pixel.dx, pixel.dy, 0);
  }

  double _depth(double px, double py, double z) {
    return floorDepth(
      px: px,
      py: py,
      z: z,
      imageWidth: floor.width.toDouble(),
      imageHeight: floor.height.toDouble(),
      yaw: yaw,
      pitch: pitch,
    );
  }

  Offset _project(double px, double py, double z) {
    return projectFloorPoint(
      px: px,
      py: py,
      z: z,
      imageWidth: floor.width.toDouble(),
      imageHeight: floor.height.toDouble(),
      projection: projection,
      yaw: yaw,
      pitch: pitch,
      scale: scale,
      panX: panX,
      panY: panY,
    );
  }

  Color _shade(Color color, double amount) {
    final argb = color.toARGB32();
    int mix(int channel) => (channel * amount).round().clamp(0, 255);
    return Color.fromARGB(
      255,
      mix((argb >> 16) & 255),
      mix((argb >> 8) & 255),
      mix(argb & 255),
    );
  }

  @override
  bool shouldRepaint(_SheetPainter oldDelegate) {
    return oldDelegate.projection != projection ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.scale != scale ||
        oldDelegate.panX != panX ||
        oldDelegate.panY != panY ||
        oldDelegate.fromId != fromId ||
        oldDelegate.toId != toId ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.showNodes != showNodes ||
        oldDelegate.showNetwork != showNetwork ||
        oldDelegate.avoidStairs != avoidStairs ||
        oldDelegate.showColor != showColor ||
        oldDelegate.floor != floor;
  }
}

String placeLabel(SheetNode node, List<SheetNode> nodes) {
  final sameName = nodes.where((other) => other.name == node.name).length;
  if (sameName == 1) return node.name;
  final zone = node.zone.replaceAll('_', ' ');
  final samePlace = nodes
      .where((other) => other.name == node.name && other.zone == node.zone)
      .length;
  if (samePlace == 1) return '${node.name} · $zone';
  final number = RegExp(r'(\d+)$').firstMatch(node.id);
  final index = number == null ? '' : ' ${int.parse(number.group(1)!)}';
  return '${node.name}$index · $zone';
}

class _PlacePickerDialog extends StatefulWidget {
  const _PlacePickerDialog({
    required this.title,
    required this.nodes,
    required this.selectedId,
  });

  final String title;
  final List<SheetNode> nodes;
  final String? selectedId;

  @override
  State<_PlacePickerDialog> createState() => _PlacePickerDialogState();
}

class _PlacePickerDialogState extends State<_PlacePickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final matches = [
      for (final node in widget.nodes)
        if (_matches(node)) node,
    ]..sort(
      (a, b) => placeLabel(
        a,
        widget.nodes,
      ).toLowerCase().compareTo(placeLabel(b, widget.nodes).toLowerCase()),
    );
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Text(
                widget.title,
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('nav-place-search'),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search places',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Text(
                          'No places match that search.',
                          style: AppTextStyles.body.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final node = matches[index];
                          return ListTile(
                            key: ValueKey('place-${node.id}'),
                            selected: node.id == widget.selectedId,
                            title: Text(placeLabel(node, widget.nodes)),
                            subtitle: Text(node.kind.replaceAll('_', ' ')),
                            onTap: () => Navigator.pop(context, node.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matches(SheetNode node) {
    if (_query.isEmpty) return true;
    final haystack =
        '${placeLabel(node, widget.nodes)} ${node.name} ${node.kind} ${node.zone}'
            .toLowerCase();
    return haystack.contains(_query.toLowerCase());
  }
}

class _DirectionsSheet extends StatelessWidget {
  const _DirectionsSheet({
    required this.title,
    required this.summary,
    required this.steps,
    required this.speaking,
    required this.onVoice,
  });

  final String title;
  final String summary;
  final List<WalkStep> steps;
  final ValueNotifier<bool> speaking;
  final Future<void> Function() onVoice;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: AppTextStyles.body.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: speaking,
                  builder: (context, isSpeaking, _) {
                    return FilledButton.icon(
                      key: const Key('nav-sheet-voice'),
                      onPressed: onVoice,
                      icon: Icon(
                        isSpeaking
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                      ),
                      label: Text(
                        isSpeaking ? 'Stop voice' : 'Voice directions',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: steps.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: palette.line),
              itemBuilder: (context, index) {
                final step = steps[index];
                return ListTile(
                  key: ValueKey('direction-$index'),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      maneuverIcon(step.maneuver),
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(step.action, style: AppTextStyles.label),
                  subtitle: step.detail.isEmpty
                      ? null
                      : Text(
                          step.detail,
                          style: AppTextStyles.body.copyWith(
                            color: palette.muted,
                            fontSize: 14,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

IconData maneuverIcon(WalkManeuver maneuver) {
  return switch (maneuver) {
    WalkManeuver.depart => Icons.trip_origin,
    WalkManeuver.straight => Icons.straight,
    WalkManeuver.slightLeft => Icons.turn_slight_left,
    WalkManeuver.left => Icons.turn_left,
    WalkManeuver.sharpLeft => Icons.turn_sharp_left,
    WalkManeuver.uTurnLeft => Icons.u_turn_left,
    WalkManeuver.slightRight => Icons.turn_slight_right,
    WalkManeuver.right => Icons.turn_right,
    WalkManeuver.sharpRight => Icons.turn_sharp_right,
    WalkManeuver.uTurnRight => Icons.u_turn_right,
    WalkManeuver.arrive => Icons.flag_outlined,
  };
}
