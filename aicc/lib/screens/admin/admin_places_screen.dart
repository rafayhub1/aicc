import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/place.dart';
import '../../services/places_repository.dart';
import '../../widgets/empty_state.dart';
import 'admin_place_form_screen.dart';

class AdminPlacesScreen extends StatefulWidget {
  const AdminPlacesScreen({super.key});

  @override
  State<AdminPlacesScreen> createState() => _AdminPlacesScreenState();
}

class _AdminPlacesScreenState extends State<AdminPlacesScreen> {
  List<CampusPlace> _places = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PlacesRepository>();
    await repo.ensureLoaded();
    if (!mounted) return;
    setState(() => _places = repo.places);
  }

  Future<void> _openForm([CampusPlace? place]) async {
    final saved = await Navigator.of(context).push<bool>(
      fadeSlideRoute<bool>(AdminPlaceFormScreen(place: place)),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _places.isEmpty
          ? const EmptyState(
              icon: Icons.place_outlined,
              title: 'No places yet',
              message: 'Add a place, or run the seed script on the server.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _places.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final place = _places[index];
                  return Semantics(
                    button: true,
                    label: 'Edit ${place.name}',
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: context.palette.card,
                      title: Text(place.name),
                      subtitle: Text('${place.category}${place.isActive ? '' : ' · hidden'}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _openForm(place),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
