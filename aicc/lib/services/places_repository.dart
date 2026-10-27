import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

class PlacesRepository {
  PlacesRepository({FirebaseFirestore? firestore, this._preferences})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final SharedPreferences? _preferences;
  final _placesController = StreamController<List<CampusPlace>>.broadcast();

  List<CampusPlace> places = [];
  Object? error;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _placesSub;

  Stream<List<CampusPlace>> get placesStream => _placesController.stream;

  Future<void> ensureLoaded() async {
    if (places.isNotEmpty) return;
    await _loadBundled();
    await _loadCache();
    _listen();
  }

  Future<void> _loadBundled() async {
    try {
      final placesRaw = await rootBundle.loadString('assets/maps/places.json');
      places = _decodePlaces(jsonDecode(placesRaw));
      _emit();
    } catch (error) {
      this.error = error;
    }
  }

  Future<void> _loadCache() async {
    final prefs = _preferences;
    if (prefs == null) return;
    final placesRaw = prefs.getString('places_cache_v1');
    if (placesRaw != null) {
      places = _decodePlaces(jsonDecode(placesRaw));
    }
    _emit();
  }

  void _listen() {
    _placesSub ??= _firestore.collection('places').snapshots().listen(
      (snapshot) async {
        if (snapshot.docs.isEmpty) return;
        places = [
          for (final doc in snapshot.docs)
            if (doc.data().isNotEmpty) CampusPlace.fromJson(doc.data(), id: doc.id),
        ]..sort((a, b) => a.name.compareTo(b.name));
        error = null;
        await _preferences?.setString(
          'places_cache_v1',
          jsonEncode([for (final place in places) place.toMap()]),
        );
        _emit();
      },
      onError: (Object error) {
        this.error = error;
        _emit();
      },
    );
  }

  List<String> recentIds() => _preferences?.getStringList('place_recent_v1') ?? const [];

  Future<void> remember(String id) async {
    final prefs = _preferences;
    if (prefs == null) return;
    final next = [id, ...recentIds().where((item) => item != id)];
    await prefs.setStringList('place_recent_v1', next.take(6).toList());
  }

  CampusPlace? byId(String id) {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  void _emit() {
    if (!_placesController.isClosed) _placesController.add(places);
  }

  Future<void> dispose() async {
    await _placesSub?.cancel();
    await _placesController.close();
  }
}

List<CampusPlace> _decodePlaces(Object? raw) {
  if (raw is! List) return [];
  return [
    for (final item in raw)
      if (item is Map) CampusPlace.fromJson(Map<String, dynamic>.from(item)),
  ];
}
