import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// Local persistence for bookmarks, reading progress and settings.
/// Same keys and JSON shapes as the web app's lib/storage.ts
/// (quran.bookmarks / quran.progress / quran.settings) so the data model
/// stays identical.
///
/// NOTE: SharedPreferences on Android lives in a different store than the
/// Capacitor WebView's localStorage, so a user updating from the old app
/// does NOT get their old bookmarks/progress carried over automatically.
/// A one-time migration (read the WebView localStorage from native code on
/// first launch) is still open — see README.md.
class Storage {
  static const _bookmarksKey = 'quran.bookmarks';
  static const _progressKey = 'quran.progress';
  static const _settingsKey = 'quran.settings';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _instance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<List<Bookmark>> getBookmarks() async {
    final prefs = await _instance();
    final raw = prefs.getString(_bookmarksKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await _instance();
    await prefs.setString(
        _bookmarksKey, jsonEncode(bookmarks.map((b) => b.toJson()).toList()));
  }

  static Future<Progress?> getProgress() async {
    final prefs = await _instance();
    final raw = prefs.getString(_progressKey);
    if (raw == null) return null;
    try {
      return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setProgress(Progress progress) async {
    final prefs = await _instance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  static Future<AppSettings> getSettings() async {
    final prefs = await _instance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return AppSettings.defaults;
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(saved);
    } catch (_) {
      return AppSettings.defaults;
    }
  }

  static Future<void> setSettings(AppSettings settings) async {
    final prefs = await _instance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
