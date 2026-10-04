import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_card.dart';
import 'campus_map.dart';

class IndoorNavigationScreen extends StatefulWidget {
  const IndoorNavigationScreen({super.key});

  @override
  State<IndoorNavigationScreen> createState() => _IndoorNavigationScreenState();
}

class _IndoorNavigationScreenState extends State<IndoorNavigationScreen>
    with SingleTickerProviderStateMixin {
  String? _from = 'gate';
  String? _to = 'cs';
  late final AnimationController _dash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  final _transform = TransformationController();
  bool _fitted = false;

  @override
  void dispose() {
    _dash.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = (_from == null || _to == null) ? const <Offset>[] : campusRoute(_from!, _to!);
    final fromPlace = placeById(_from);
    final toPlace = placeById(_to);
    final summary = fromPlace == null || toPlace == null
        ? 'Choose a starting point and a destination.'
        : fromPlace.id == toPlace.id
            ? 'Pick two different places.'
            : route.isEmpty
                ? 'No walkway connects those places.'
                : 'Walk from ${fromPlace.name} to ${toPlace.name}.';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              _picker('From', _from, (value) => setState(() => _from = value)),
              const SizedBox(height: 12),
              _picker('To', _to, (value) => setState(() => _to = value)),
              const SizedBox(height: 12),
              Text(summary, style: const TextStyle(height: 1.35, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 420,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: ColoredBox(
              color: const Color(0xFFE7EDF3),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!_fitted) {
                    final scale = constraints.maxWidth / 1000;
                    _transform.value = Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
                    _fitted = true;
                  }
                  return InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    minScale: 0.25,
                    maxScale: 2.8,
                    boundaryMargin: const EdgeInsets.all(120),
                    child: AnimatedBuilder(
                      animation: _dash,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(1000, 800),
                          painter: CampusMapPainter(
                            route: route,
                            dashPhase: _dash.value * 24,
                            fromId: _from,
                            toId: _to,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LegendDot(color: AppColors.primary, label: 'Academic'),
            _LegendDot(color: AppColors.primaryLight, label: 'Admin'),
            _LegendDot(color: AppColors.accent, label: 'Student life'),
            _LegendDot(color: AppColors.muted, label: 'Entry'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Pinch to zoom and drag to move around the campus.',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _picker(String label, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final place in campusPlaces)
          DropdownMenuItem(value: place.id, child: Text(place.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
