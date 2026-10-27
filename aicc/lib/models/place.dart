class CampusPlace {
  const CampusPlace({
    required this.id,
    required this.name,
    required this.aliases,
    required this.category,
    required this.lat,
    required this.lng,
    required this.entranceLat,
    required this.entranceLng,
    required this.building,
    required this.floor,
    required this.hours,
    required this.description,
    required this.photoUrl,
    required this.nodeId,
    required this.isActive,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String category;
  final double lat;
  final double lng;
  final double entranceLat;
  final double entranceLng;
  final String building;
  final String floor;
  final String hours;
  final String description;
  final String photoUrl;
  final String nodeId;
  final bool isActive;

  bool get hasPhoto => photoUrl.trim().isNotEmpty;

  String get placeLabel {
    if (building.isEmpty) return floor.isEmpty ? category : floor;
    if (floor.isEmpty) return building;
    return '$building · $floor';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'aliases': aliases,
      'category': category,
      'lat': lat,
      'lng': lng,
      'entrance': {'lat': entranceLat, 'lng': entranceLng},
      'building': building,
      'floor': floor,
      'hours': hours,
      'description': description,
      'photoUrl': photoUrl,
      'nodeId': nodeId,
      'isActive': isActive,
    };
  }

  factory CampusPlace.fromJson(Map<String, dynamic> json, {String? id}) {
    final entrance = json['entrance'];
    final entranceLat = entrance is Map ? entrance['lat'] : json['entranceLat'];
    final entranceLng = entrance is Map ? entrance['lng'] : json['entranceLng'];
    final aliases = json['aliases'];
    return CampusPlace(
      id: (id ?? json['id'] ?? '').toString(),
      name: '${json['name'] ?? ''}',
      aliases: aliases is List ? aliases.map((item) => '$item'.trim()).where((item) => item.isNotEmpty).toList() : const [],
      category: '${json['category'] ?? 'Academic'}',
      lat: _num(json['lat']),
      lng: _num(json['lng']),
      entranceLat: _num(entranceLat ?? json['lat']),
      entranceLng: _num(entranceLng ?? json['lng']),
      building: '${json['building'] ?? ''}',
      floor: '${json['floor'] ?? ''}',
      hours: '${json['hours'] ?? ''}',
      description: '${json['description'] ?? ''}',
      photoUrl: '${json['photoUrl'] ?? ''}',
      nodeId: '${json['nodeId'] ?? ''}',
      isActive: json['isActive'] != false,
    );
  }

  CampusPlace copyWith({
    String? name,
    List<String>? aliases,
    String? category,
    double? lat,
    double? lng,
    String? building,
    String? floor,
    String? hours,
    String? description,
    String? photoUrl,
    String? nodeId,
    bool? isActive,
  }) {
    return CampusPlace(
      id: id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      entranceLat: lat ?? entranceLat,
      entranceLng: lng ?? entranceLng,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      nodeId: nodeId ?? this.nodeId,
      isActive: isActive ?? this.isActive,
    );
  }
}

double _num(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

const placeCategories = [
  'Academic',
  'Admin',
  'Food',
  'Library',
  'Labs',
  'Prayer',
  'Sports',
  'Parking',
  'Gates',
  'Washrooms',
];
