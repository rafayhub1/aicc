import 'package:flutter/material.dart';

class MapLayerChoice {
  const MapLayerChoice({
    required this.id,
    required this.label,
    required this.selected,
  });

  final String id;
  final String label;
  final bool selected;
}

class MapControlRail extends StatelessWidget {
  const MapControlRail({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.accessible,
    required this.onAccessible,
    required this.layers,
    required this.onLayer,
  });

  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool accessible;
  final VoidCallback onAccessible;
  final List<MapLayerChoice> layers;
  final ValueChanged<String> onLayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circle(
          key: const Key('map-recenter'),
          tooltip: 'Recenter map',
          icon: Icons.gps_fixed_rounded,
          onTap: onRecenter,
        ),
        const SizedBox(height: 10),
        _circle(
          key: const Key('map-zoom-in'),
          tooltip: 'Zoom in',
          icon: Icons.add_rounded,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 10),
        _circle(
          key: const Key('map-zoom-out'),
          tooltip: 'Zoom out',
          icon: Icons.remove_rounded,
          onTap: onZoomOut,
        ),
        const SizedBox(height: 10),
        _circle(
          key: const Key('map-access'),
          tooltip: 'Step-free route',
          icon: Icons.accessible_rounded,
          selected: accessible,
          onTap: onAccessible,
        ),
        const SizedBox(height: 10),
        PopupMenuButton<String>(
          tooltip: 'Layers',
          offset: const Offset(-168, 0),
          onSelected: onLayer,
          itemBuilder: (context) => [
            for (final layer in layers)
              PopupMenuItem(
                value: layer.id,
                child: Row(
                  children: [
                    Icon(
                      layer.selected ? Icons.check_rounded : Icons.circle_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(layer.label),
                  ],
                ),
              ),
          ],
          child: _face(
            key: const Key('map-layers'),
            tooltip: 'Layers',
            icon: Icons.layers_rounded,
          ),
        ),
      ],
    );
  }

  Widget _circle({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return _face(
      key: key,
      tooltip: tooltip,
      icon: icon,
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _face({
    required Key key,
    required String tooltip,
    required IconData icon,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: key,
        color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF1C2430),
        elevation: 6,
        shadowColor: const Color(0x66000000),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
