import 'package:flutter/foundation.dart';
import '../data/storage.dart';
import '../models.dart';

/// App-wide state: settings, bookmarks, reading progress.
/// Mirrors src/context/AppContext.tsx (same defaults, same behaviors).
class AppState extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults;
  List<Bookmark> _bookmarks = [];
  Progress? _progress;
  bool _loaded = false;

  AppSettings get settings => _settings;
  List<Bookmark> get bookmarks => _bookmarks;
  Progress? get progress => _progress;
  bool get loaded => _loaded;

  /// A pending request to open the Mushaf tab at a given page (used by
  /// Continue Reading, search results, bookmarks and tafseer links).
  /// The shell consumes it and switches to the Mushaf tab.
  int? _mushafPageRequest;
  int? get mushafPageRequest => _mushafPageRequest;

  void requestMushafPage(int page) {
    _mushafPageRequest = page;
    notifyListeners();
  }

  void clearMushafPageRequest() {
    _mushafPageRequest = null;
  }

  /// A pending request to switch to the Quran index tab (from Home's
  /// "View All"). The shell consumes it the same way as the mushaf one.
  bool _indexTabRequest = false;
  bool get indexTabRequest => _indexTabRequest;

  void requestIndexTab() {
    _indexTabRequest = true;
    notifyListeners();
  }

  void clearIndexTabRequest() {
    _indexTabRequest = false;
  }

  Future<void> load() async {
    _settings = await Storage.getSettings();
    _bookmarks = await Storage.getBookmarks();
    _progress = await Storage.getProgress();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSettings(AppSettings Function(AppSettings) patch) async {
    final next = patch(_settings);
    // The web app forces Hafs + scrolling when the UI language is English
    // (Arabic-only features: Warsh mushaf, pages mode, tajweed).
    var fixed = next;
    if (fixed.language == 'english' &&
        (fixed.mushaf != Mushaf.hafs ||
            fixed.navigationStyle != NavStyle.scrolling)) {
      fixed = fixed.copyWith(
          mushaf: Mushaf.hafs, navigationStyle: NavStyle.scrolling);
    }
    _settings = fixed;
    await Storage.setSettings(_settings);
    notifyListeners();
  }

  bool isBookmarked(int surah, int ayah) =>
      _bookmarks.any((x) => x.surah == surah && x.ayah == ayah);

  Future<void> toggleBookmark(Bookmark b) async {
    final exists = _bookmarks
        .any((x) => x.surah == b.surah && x.ayah == b.ayah);
    if (exists) {
      _bookmarks = _bookmarks
          .where((x) => !(x.surah == b.surah && x.ayah == b.ayah))
          .toList();
    } else {
      _bookmarks = [
        Bookmark(
          surah: b.surah,
          ayah: b.ayah,
          preview: b.preview,
          mushaf: b.mushaf,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        ..._bookmarks,
      ];
    }
    await Storage.setBookmarks(_bookmarks);
    notifyListeners();
  }

  Future<void> saveProgress(Progress p) async {
    _progress = p;
    await Storage.setProgress(p);
    notifyListeners();
  }
}
