import 'dart:convert';
import 'package:flutter/services.dart';

/// Warsh -> Hafs verse correspondence, derived from the verse texts
/// themselves (sequence alignment of the two datasets).
/// Direct port of src/lib/verseMapping.ts.
///
/// Format: only surahs whose numbering differs from Hafs are present.
/// Each entry is an array indexed by (warshVerse - 1); each value is the
/// list of Hafs verses with the same content:
/// - usually one verse (e.g. Warsh 2:2 -> Hafs 2:3),
/// - two when one Warsh verse joins two Hafs verses,
/// - shared when Warsh splits one Hafs verse in two.
/// Surahs absent from the file are identical in both readings.
class VerseMapping {
  static Map<String, List<List<int>>>? _map;
  static Map<String, Map<int, int>>? _reverseCache;

  static Future<Map<String, List<List<int>>>> _loadMap() async {
    if (_map != null) return _map!;
    final raw =
        await rootBundle.loadString('assets/data/warshToHafs.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _map = decoded.map((k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => (e as List).map((n) => (n as num).toInt()).toList())
            .toList()));
    return _map!;
  }

  /// Hafs verse(s) with the same content as a Warsh verse (at least one).
  static Future<List<int>> warshToHafs(int surah, int warshVerse) async {
    final map = await _loadMap();
    final arr = map[surah.toString()];
    if (arr == null) return [warshVerse];
    if (warshVerse - 1 < 0 || warshVerse - 1 >= arr.length) {
      return [warshVerse];
    }
    return arr[warshVerse - 1];
  }

  /// The full Warsh -> Hafs array for a surah, or null if identical to Hafs.
  static Future<List<List<int>>?> getWarshMapForSurah(int surah) async {
    final map = await _loadMap();
    return map[surah.toString()];
  }

  /// Warsh verse with the same content as a Hafs verse, or null when there
  /// is none (only Fatiha's Bismillah, Hafs 1:1). For a Hafs verse split
  /// into two Warsh verses, the first Warsh verse wins.
  static Future<int?> hafsToWarsh(int surah, int hafsVerse) async {
    final map = await _loadMap();
    final arr = map[surah.toString()];
    if (arr == null) return hafsVerse;
    _reverseCache ??= {};
    var rev = _reverseCache![surah.toString()];
    if (rev == null) {
      rev = {};
      for (final entry in map.entries) {
        final r = <int, int>{};
        for (var idx = 0; idx < entry.value.length; idx++) {
          for (final h in entry.value[idx]) {
            r.putIfAbsent(h, () => idx + 1);
          }
        }
        _reverseCache![entry.key] = r;
      }
      rev = _reverseCache![surah.toString()]!;
    }
    return rev[hafsVerse];
  }
}
