import '../models/place.dart';

const navigationPhrases = [
  'where is',
  'where are',
  "where's",
  'how do i get to',
  'how to reach',
  'how do i reach',
  'navigate to',
  'take me to',
  'directions to',
  'direction to',
  'kahan hai',
  'kahan he',
  'kidhar hai',
  'kidhar he',
];

const _fillers = {
  'the',
  'a',
  'an',
  'to',
  'please',
  'me',
  'is',
  'are',
  'hai',
  'he',
  'kahan',
  'kidhar',
  'where',
  'how',
  'do',
  'i',
  'get',
  'reach',
  'navigate',
  'take',
  'directions',
  'direction',
};

String normalizePlaceText(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp("[^a-z0-9\\s]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool isNavigationQuery(String normalized) {
  for (final phrase in navigationPhrases) {
    if (normalized.contains(phrase)) return true;
  }
  return false;
}

/// Longest place name or alias wins. A bare name ("LGU") matches too.
/// A sentence that only mentions a place ("when does the library open") does not.
CampusPlace? matchPlace(String raw, List<CampusPlace> places) {
  final text = normalizePlaceText(raw);
  if (text.isEmpty) return null;
  final active = [for (final place in places) if (place.isActive) place];
  final contained = _longestContained(text, active);
  if (contained == null) {
    if (!isNavigationQuery(text)) return null;
    return _fuzzy(text, active);
  }
  if (isNavigationQuery(text) || _mostlyPlace(text, contained)) return contained;
  return null;
}

CampusPlace? nearestPlace(List<CampusPlace> places, String category, double lat, double lng) {
  CampusPlace? best;
  var bestDistance = double.infinity;
  for (final place in places) {
    if (!place.isActive || place.category.toLowerCase() != category.toLowerCase()) continue;
    final distance = _rough(lat, lng, place.lat, place.lng);
    if (distance < bestDistance) {
      best = place;
      bestDistance = distance;
    }
  }
  return best;
}

bool placeOpenNow(String hours, DateTime now) {
  final match = RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(hours);
  if (match == null) return false;
  final start = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  final end = int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!);
  final minute = now.hour * 60 + now.minute;
  if (end >= start) return minute >= start && minute <= end;
  return minute >= start || minute <= end;
}

bool hoursKnown(String hours) => RegExp(r'\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}').hasMatch(hours);

CampusPlace? _longestContained(String text, List<CampusPlace> places) {
  CampusPlace? best;
  var bestLength = 0;
  for (final place in places) {
    for (final alias in _labels(place)) {
      if (alias.length > bestLength && _containsPhrase(text, alias)) {
        best = place;
        bestLength = alias.length;
      }
    }
  }
  return best;
}

bool _mostlyPlace(String text, CampusPlace place) {
  var rest = text;
  final labels = _labels(place).toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final alias in labels) {
    if (_containsPhrase(rest, alias)) {
      rest = rest.replaceFirst(alias, ' ');
      break;
    }
  }
  final words = rest.split(' ').where((word) => word.isNotEmpty && !_fillers.contains(word));
  return words.isEmpty;
}

CampusPlace? _fuzzy(String text, List<CampusPlace> places) {
  final words = text.split(' ').where((word) => word.length >= 5).toList();
  CampusPlace? best;
  var bestLength = 0;
  for (final place in places) {
    for (final alias in _labels(place)) {
      for (final token in alias.split(' ')) {
        if (token.length < 5) continue;
        for (final word in words) {
          if (_distance(word, token) <= 1 && token.length > bestLength) {
            best = place;
            bestLength = token.length;
          }
        }
      }
    }
  }
  return best;
}

Iterable<String> _labels(CampusPlace place) sync* {
  yield normalizePlaceText(place.name);
  for (final alias in place.aliases) {
    yield normalizePlaceText(alias);
  }
}

bool _containsPhrase(String text, String phrase) {
  if (phrase.isEmpty) return false;
  return RegExp('(^| )${RegExp.escape(phrase)}( |\$)').hasMatch(text);
}

int _distance(String a, String b) {
  if ((a.length - b.length).abs() > 1) return 2;
  final rows = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    rows[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    rows[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      rows[i][j] = [
        rows[i - 1][j] + 1,
        rows[i][j - 1] + 1,
        rows[i - 1][j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  return rows[a.length][b.length];
}

double _rough(double lat1, double lng1, double lat2, double lng2) {
  final dLat = lat1 - lat2;
  final dLng = lng1 - lng2;
  return dLat * dLat + dLng * dLng;
}
