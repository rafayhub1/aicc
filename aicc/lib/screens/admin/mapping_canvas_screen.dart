import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../features/navigation_mode/data/sheet_draft_store.dart';
import '../../features/navigation_mode/domain/map_color.dart';
import '../../features/navigation_mode/domain/sheet_editor.dart';
import '../../features/navigation_mode/domain/sheet_map.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/map_control_rail.dart';

enum _CanvasTool { select, building, node, pathway, entry }

const _nodeKinds = [
  'building',
  'classroom',
  'office',
  'lab',
  'toilet',
  'gate',
  'canteen',
  'stairs',
  'parking',
  'hall',
  'library',
];

class MappingCanvasScreen extends StatefulWidget {
  const MappingCanvasScreen({super.key});

  @override
  State<MappingCanvasScreen> createState() => _MappingCanvasScreenState();
}

class _MappingCanvasScreenState extends State<MappingCanvasScreen> {
  final TransformationController _view = TransformationController();
  Map<String, dynamic>? _document;
  GroundSheet? _sheet;
  ui.Image? _floor;
  Object? _error;
  bool _fitted = false;
  Size? _viewport;
  bool _showFloor = true;
  bool _showNodes = true;
  bool _showPaths = true;
  bool _showColor = true;
  bool _stepFree = false;
  _CanvasTool _tool = _CanvasTool.select;
  String? _selectedId;
  int? _selectedEdge;
  String? _selectedEntry;
  String? _entryRoom;
  Offset? _pathStart;
  final Map<String, Offset> _drag = {};
  final Map<String, Offset> _entryDrag = {};

  @override
  void initState() {
    super.initState();
    _load(saved: true);
  }

  @override
  void dispose() {
    _view.dispose();
    _floor?.dispose();
    super.dispose();
  }

  Future<void> _load({required bool saved}) async {
    try {
      final Map<String, dynamic> document;
      if (saved) {
        document = await SheetDraftStore.read() ?? await _asset();
      } else {
        document = await _asset();
      }
      final sheet = GroundSheet.parse(document);
      final data = await rootBundle.load(GroundSheet.floorAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      _floor?.dispose();
      setState(() {
        _document = document;
        _sheet = sheet;
        _floor = frame.image;
        _error = null;
        _fitted = false;
        _selectedId = null;
        _selectedEdge = null;
        _selectedEntry = null;
        _entryRoom = null;
        _pathStart = null;
        _drag.clear();
        _entryDrag.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<Map<String, dynamic>> _asset() async {
    final raw = jsonDecode(await rootBundle.loadString(GroundSheet.asset));
    if (raw is! Map) {
      throw const FormatException('Ground sheet is not an object.');
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<void> _commit() async {
    final document = _document;
    if (document == null) return;
    final sheet = GroundSheet.parse(document);
    setState(() => _sheet = sheet);
    await SheetDraftStore.write(document);
  }

  Offset _sheetPoint(Offset scene) {
    final sheet = _sheet!;
    final floor = _floor!;
    return Offset(
      scene.dx / floor.width * sheet.pageWidth,
      scene.dy / floor.height * sheet.pageHeight,
    );
  }

  Offset _scenePoint(double x, double y) {
    final sheet = _sheet!;
    final floor = _floor!;
    return Offset(
      x / sheet.pageWidth * floor.width,
      y / sheet.pageHeight * floor.height,
    );
  }

  Offset _place(SheetNode node) => _drag[node.id] ?? Offset(node.x, node.y);

  void _fit(Size viewport, {bool force = false}) {
    _viewport = viewport;
    final floor = _floor;
    if (floor == null || viewport.width <= 0) return;
    if (_fitted && !force) return;
    final scale = viewport.width / floor.width;
    final dy = math.max(0.0, (viewport.height - floor.height * scale) / 2);
    _view.value = Matrix4.identity()
      ..translateByDouble(0, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _fitted = true;
  }

  void _zoomBy(double factor) {
    final viewport = _viewport;
    if (viewport == null || viewport.width <= 0) return;
    final scale = _view.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.12, 8.0);
    if ((next - scale).abs() < 0.0001) return;
    final applied = next / scale;
    final scene = _view.toScene(Offset(viewport.width / 2, viewport.height / 2));
    final matrix = _view.value.clone();
    matrix.translateByDouble(scene.dx, scene.dy, 0, 1);
    matrix.scaleByDouble(applied, applied, 1, 1);
    matrix.translateByDouble(-scene.dx, -scene.dy, 0, 1);
    _view.value = matrix;
  }

  bool get _accessLit {
    final sheet = _sheet;
    final edge = _selectedEdge;
    if (sheet != null && edge != null && edge >= 0 && edge < sheet.edges.length) {
      return sheet.edges[edge].stairs;
    }
    return _stepFree;
  }

  Future<void> _toggleAccess() async {
    final document = _document;
    final sheet = _sheet;
    final edge = _selectedEdge;
    if (document != null &&
        sheet != null &&
        edge != null &&
        edge >= 0 &&
        edge < sheet.edges.length) {
      setPathwayStairs(document, edge, !sheet.edges[edge].stairs);
      await _commit();
      return;
    }
    setState(() => _stepFree = !_stepFree);
  }

  void _chooseLayer(String id) {
    setState(() {
      if (id == 'floor') _showFloor = !_showFloor;
      if (id == 'nodes') _showNodes = !_showNodes;
      if (id == 'paths') _showPaths = !_showPaths;
      if (id == 'color') _showColor = !_showColor;
    });
  }

  Future<void> _onCanvasTap(Offset scene) async {
    final document = _document;
    final sheet = _sheet;
    if (document == null || sheet == null) return;
    final point = _sheetPoint(scene);
    if (_tool == _CanvasTool.entry) {
      final room = _entryRoom;
      if (room == null) return;
      final id = addEntry(document, room, point.dx, point.dy);
      setState(() {
        _selectedEntry = id;
        _selectedId = null;
        _selectedEdge = null;
      });
      await _commit();
      return;
    }
    if (_tool == _CanvasTool.pathway) {
      setState(() {
        _selectedId = null;
        _selectedEdge = null;
        _selectedEntry = null;
        if (_pathStart == null) {
          _pathStart = point;
        } else {
          addPathway(document, _pathStart!.dx, _pathStart!.dy, point.dx, point.dy);
          _pathStart = null;
        }
      });
      if (_pathStart == null) await _commit();
      return;
    }
    if (_tool == _CanvasTool.building || _tool == _CanvasTool.node) {
      final draft = await _askPlace(
        title: _tool == _CanvasTool.building ? 'New building' : 'New node',
        kind: _tool == _CanvasTool.building ? 'building' : 'classroom',
        lockKind: _tool == _CanvasTool.building,
      );
      if (draft == null || !mounted) return;
      final id = addPlace(
        document,
        name: draft.name,
        kind: draft.kind,
        x: point.dx,
        y: point.dy,
      );
      setState(() {
        _selectedId = id;
        _selectedEdge = null;
        _selectedEntry = null;
        _tool = _CanvasTool.select;
      });
      await _commit();
      return;
    }
    final edge = pathwayIndexNear(document, point.dx, point.dy);
    setState(() {
      _selectedId = null;
      _selectedEdge = edge < 0 ? null : edge;
      _selectedEntry = null;
      _pathStart = null;
    });
  }

  Future<void> _rename() async {
    final document = _document;
    final sheet = _sheet;
    final id = _selectedId;
    if (document == null || sheet == null || id == null) return;
    final node = sheet.nodeById(id);
    if (node == null) return;
    final draft = await _askPlace(
      title: node.kind == 'building' ? 'Rename building' : 'Rename node',
      kind: node.kind,
      initial: node.name,
      lockKind: false,
    );
    if (draft == null || !mounted) return;
    renamePlace(document, id, name: draft.name, kind: draft.kind);
    await _commit();
  }

  Future<void> _deleteSelection() async {
    final document = _document;
    if (document == null) return;
    final edge = _selectedEdge;
    final id = _selectedId;
    final entryId = _selectedEntry;
    if (edge == null && id == null && entryId == null) return;
    final sheet = _sheet;
    final node = id == null || sheet == null ? null : sheet.nodeById(id);
    final confirmed = await confirmAction(
      context,
      title: entryId != null
          ? 'Remove this door?'
          : edge != null
          ? 'Remove this pathway?'
          : 'Remove ${node?.name ?? 'this place'}?',
      message: entryId != null
          ? 'Routes will stop using this entrance.'
          : edge != null
          ? 'The blue route will no longer be able to walk this segment.'
          : 'This removes the place and its doors from the map.',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    if (entryId != null) {
      deleteEntry(document, entryId);
    } else if (edge != null) {
      deletePathwayAt(document, edge);
    } else if (id != null) {
      deletePlace(document, id);
    }
    setState(() {
      _selectedId = null;
      _selectedEdge = null;
      _selectedEntry = null;
      if (id != null && _entryRoom == id) _entryRoom = null;
    });
    await _commit();
  }

  Future<void> _restore() async {
    final confirmed = await confirmAction(
      context,
      title: 'Restore the original map?',
      message: 'Buildings, nodes, and pathways you added or moved on this phone will be cleared.',
      confirmLabel: 'Restore',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await SheetDraftStore.clear();
    await _load(saved: false);
  }

  Future<_PlaceDraft?> _askPlace({
    required String title,
    required String kind,
    String initial = '',
    required bool lockKind,
  }) {
    return showDialog<_PlaceDraft>(
      context: context,
      builder: (context) => _PlaceDialog(
        title: title,
        initialName: initial,
        initialKind: kind,
        lockKind: lockKind,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapping and Canvasing'),
        actions: [
          IconButton(
            tooltip: 'Restore original map',
            onPressed: _sheet == null ? null : _restore,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          _tools(),
          Expanded(child: _canvas()),
          if (_selectedId != null || _selectedEdge != null || _selectedEntry != null)
            _selectionBar(),
        ],
      ),
    );
  }

  Widget _tools() {
    return Material(
      color: context.palette.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          children: [
            Row(
              children: [
                _toolButton(_CanvasTool.select, Icons.open_with_rounded, 'Move'),
                _toolButton(_CanvasTool.building, Icons.domain_rounded, 'Building'),
                _toolButton(_CanvasTool.node, Icons.place_outlined, 'Node'),
                _toolButton(_CanvasTool.pathway, Icons.route_rounded, 'Pathway'),
                _toolButton(_CanvasTool.entry, Icons.door_front_door_outlined, 'Door'),
              ],
            ),
            const SizedBox(height: 4),
            Text(_hint(), style: AppTextStyles.muted.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _hint() {
    return switch (_tool) {
      _CanvasTool.select =>
        'Drag a building or node to move it. Tap a pathway to select it.',
      _CanvasTool.building => 'Tap the map to place a building.',
      _CanvasTool.node => 'Tap the map to place a node.',
      _CanvasTool.pathway => _pathStart == null
          ? 'Tap the start of a new pathway.'
          : 'Tap the other end. The new pathway joins a nearby path.',
      _CanvasTool.entry => _entryHint(),
    };
  }

  String _entryHint() {
    final room = _entryRoom;
    final sheet = _sheet;
    if (room == null || sheet == null) {
      return 'Tap a classroom or building, then tap each door.';
    }
    final name = sheet.nodeById(room)?.name ?? 'this place';
    return 'Doors for $name. Tap each entrance. Routes use the closest one.';
  }

  Widget _toolButton(_CanvasTool tool, IconData icon, String label) {
    final selected = _tool == tool;
    final color = selected ? AppColors.primary : context.palette.ink;
    return Expanded(
      child: InkWell(
        key: Key('map-tool-$label'),
        onTap: () => setState(() {
          _tool = tool;
          _pathStart = null;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas() {
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
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _fit(viewport);
        return Stack(
          children: [
            InteractiveViewer(
          transformationController: _view,
          minScale: 0.12,
          maxScale: 8,
          boundaryMargin: const EdgeInsets.all(240),
          constrained: false,
          child: SizedBox(
            width: floor.width.toDouble(),
            height: floor.height.toDouble(),
            child: Stack(
              children: [
                GestureDetector(
                  key: const Key('mapping-canvas'),
                  onTapUp: (details) => _onCanvasTap(details.localPosition),
                  child: CustomPaint(
                    size: Size(floor.width.toDouble(), floor.height.toDouble()),
                    painter: _CanvasPainter(
                      floor: floor,
                      sheet: sheet,
                      selectedEdge: _selectedEdge,
                      pathStart: _pathStart,
                      showFloor: _showFloor,
                      showPaths: _showPaths,
                      hideStairs: _stepFree,
                      showColor: _showColor,
                    ),
                  ),
                ),
                for (final node in sheet.nodes)
                  if (_showNodes || node.id == _selectedId || node.id == _entryRoom)
                    _nodeMarker(node),
                for (final entry in sheet.entries) _entryMarker(entry),
              ],
            ),
          ),
            ),
            Positioned(
              right: 10,
              top: 8,
              child: MapControlRail(
                onRecenter: () => _fit(viewport, force: true),
                onZoomIn: () => _zoomBy(1.25),
                onZoomOut: () => _zoomBy(1 / 1.25),
                accessible: _accessLit,
                onAccessible: _toggleAccess,
                layers: [
                  MapLayerChoice(id: 'floor', label: 'Floor plan', selected: _showFloor),
                  MapLayerChoice(id: 'nodes', label: 'Nodes', selected: _showNodes),
                  MapLayerChoice(id: 'paths', label: 'Pathways', selected: _showPaths),
                  MapLayerChoice(id: 'color', label: 'Color', selected: _showColor),
                ],
                onLayer: _chooseLayer,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _nodeMarker(SheetNode node) {
    final at = _scenePoint(_place(node).dx, _place(node).dy);
    final building = node.kind == 'building';
    final selected = node.id == _selectedId;
    final size = building ? 36.0 : 22.0;
    final color = node.kind == 'building'
        ? AppColors.primary
        : sheetKindColor(node.kind);
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedEdge = null;
          _pathStart = null;
          _selectedEntry = null;
          if (_tool == _CanvasTool.entry) {
            _entryRoom = node.id;
            _selectedId = node.id;
            return;
          }
          _selectedId = node.id;
          _tool = _CanvasTool.select;
        }),
        onPanUpdate: _tool == _CanvasTool.select
            ? (details) {
                final scale = _view.value.getMaxScaleOnAxis();
                final sheet = _sheet!;
                final floor = _floor!;
                final current = _place(node);
                setState(() {
                  _selectedId = node.id;
                  _selectedEdge = null;
                  _drag[node.id] = Offset(
                    current.dx + details.delta.dx / scale * sheet.pageWidth / floor.width,
                    current.dy + details.delta.dy / scale * sheet.pageHeight / floor.height,
                  );
                });
              }
            : null,
        onPanEnd: _tool == _CanvasTool.select
            ? (_) {
                final moved = _drag[node.id];
                final document = _document;
                if (moved == null || document == null) return;
                movePlace(document, node.id, moved.dx, moved.dy);
                setState(() {
                  _drag.remove(node.id);
                  _sheet = GroundSheet.parse(document);
                });
                SheetDraftStore.write(document);
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: building ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: building ? BorderRadius.circular(6) : null,
                border: Border.all(
                  color: selected ? const Color(0xFFF59E0B) : Colors.white,
                  width: selected ? 3 : 2,
                ),
              ),
            ),
            if (building || selected)
              Text(
                node.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1917),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _entryMarker(SheetEntry entry) {
    final dragged = _entryDrag[entry.id];
    final at = _scenePoint(dragged?.dx ?? entry.x, dragged?.dy ?? entry.y);
    final selected = entry.id == _selectedEntry;
    const size = 28.0;
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedEntry = entry.id;
          _entryRoom = entry.room;
          _selectedId = null;
          _selectedEdge = null;
          _tool = _CanvasTool.entry;
        }),
        onPanUpdate: (details) {
          final scale = _view.value.getMaxScaleOnAxis();
          final sheet = _sheet!;
          final floor = _floor!;
          final current = dragged ?? Offset(entry.x, entry.y);
          setState(() {
            _selectedEntry = entry.id;
            _entryRoom = entry.room;
            _selectedId = null;
            _selectedEdge = null;
            _entryDrag[entry.id] = Offset(
              current.dx + details.delta.dx / scale * sheet.pageWidth / floor.width,
              current.dy + details.delta.dy / scale * sheet.pageHeight / floor.height,
            );
          });
        },
        onPanEnd: (_) {
          final moved = _entryDrag[entry.id];
          final document = _document;
          if (moved == null || document == null) return;
          moveEntry(document, entry.id, moved.dx, moved.dy);
          setState(() {
            _entryDrag.remove(entry.id);
            _sheet = GroundSheet.parse(document);
          });
          SheetDraftStore.write(document);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F766E) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0F766E),
              width: selected ? 3 : 2,
            ),
          ),
          child: Icon(
            Icons.door_front_door_outlined,
            size: 16,
            color: selected ? Colors.white : const Color(0xFF0F766E),
          ),
        ),
      ),
    );
  }

  Widget _selectionBar() {
    final sheet = _sheet;
    final entry = _selectedEntry == null || sheet == null
        ? null
        : sheet.entryById(_selectedEntry!);
    final node = _selectedId == null || sheet == null
        ? null
        : sheet.nodeById(_selectedId!);
    final title = entry != null ? 'Door' : node?.name ?? 'Pathway';
    final detail = entry != null
        ? (sheet?.nodeById(entry.room)?.name ?? 'Entrance')
        : node == null
        ? 'Selected segment'
        : node.kind.replaceAll('_', ' ');
    return Material(
      color: context.palette.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label),
                  Text(detail, style: AppTextStyles.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            if (node != null)
              TextButton(onPressed: _rename, child: const Text('Rename')),
            TextButton(
              onPressed: _deleteSelection,
              child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceDraft {
  const _PlaceDraft(this.name, this.kind);
  final String name;
  final String kind;
}

class _PlaceDialog extends StatefulWidget {
  const _PlaceDialog({
    required this.title,
    required this.initialName,
    required this.initialKind,
    required this.lockKind,
  });

  final String title;
  final String initialName;
  final String initialKind;
  final bool lockKind;

  @override
  State<_PlaceDialog> createState() => _PlaceDialogState();
}

class _PlaceDialogState extends State<_PlaceDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  late String _kind = widget.initialKind == 'building' || _nodeKinds.contains(widget.initialKind)
      ? widget.initialKind
      : 'classroom';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          if (!widget.lockKind) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _nodeKinds.contains(_kind) ? _kind : 'classroom',
              decoration: const InputDecoration(labelText: 'Kind'),
              items: [
                for (final kind in _nodeKinds)
                  DropdownMenuItem(value: kind, child: Text(kind.replaceAll('_', ' '))),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _kind = value);
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _PlaceDraft(name, widget.lockKind ? 'building' : _kind),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CanvasPainter extends CustomPainter {
  const _CanvasPainter({
    required this.floor,
    required this.sheet,
    required this.selectedEdge,
    required this.pathStart,
    required this.showFloor,
    required this.showPaths,
    required this.hideStairs,
    required this.showColor,
  });

  final ui.Image floor;
  final GroundSheet sheet;
  final int? selectedEdge;
  final Offset? pathStart;
  final bool showFloor;
  final bool showPaths;
  final bool hideStairs;
  final bool showColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (showColor) {
      paintCampusColors(
        canvas: canvas,
        sheet: sheet,
        imageWidth: floor.width.toDouble(),
        imageHeight: floor.height.toDouble(),
        map: (x, y) => Offset(x, y),
      );
    }
    if (showFloor) {
      canvas.drawImage(
        floor,
        Offset.zero,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..blendMode = showColor ? BlendMode.multiply : BlendMode.srcOver,
      );
    } else if (!showColor) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE7E5E4));
    }
    for (final entry in sheet.entries) {
      final node = sheet.nodeById(entry.room);
      if (node == null) continue;
      canvas.drawLine(
        _pixel(node.x, node.y),
        _pixel(entry.x, entry.y),
        Paint()
          ..color = const Color(0xFF0F766E)
          ..strokeWidth = 3,
      );
    }
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final stairs = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final selected = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < sheet.edges.length; i++) {
      final edge = sheet.edges[i];
      if (!showPaths && i != selectedEdge) continue;
      if (hideStairs && edge.stairs && i != selectedEdge) continue;
      final path = Path();
      for (var p = 0; p < edge.points.length; p++) {
        final at = _pixel(edge.points[p].x, edge.points[p].y);
        if (p == 0) {
          path.moveTo(at.dx, at.dy);
        } else {
          path.lineTo(at.dx, at.dy);
        }
      }
      canvas.drawPath(
        path,
        i == selectedEdge ? selected : (edge.stairs ? stairs : paint),
      );
    }
    final start = pathStart;
    if (start != null) {
      final at = _pixel(start.dx, start.dy);
      canvas.drawCircle(at, 10, Paint()..color = const Color(0xFF1D4ED8));
    }
  }

  Offset _pixel(double x, double y) {
    return Offset(
      x / sheet.pageWidth * floor.width,
      y / sheet.pageHeight * floor.height,
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) {
    return oldDelegate.sheet != sheet ||
        oldDelegate.selectedEdge != selectedEdge ||
        oldDelegate.pathStart != pathStart ||
        oldDelegate.showFloor != showFloor ||
        oldDelegate.showPaths != showPaths ||
        oldDelegate.hideStairs != hideStairs ||
        oldDelegate.showColor != showColor ||
        oldDelegate.floor != floor;
  }
}
