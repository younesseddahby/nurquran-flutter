import 'dart:convert';
import 'package:flutter/services.dart';
import '../models.dart';
import 'verse_mapping.dart';

/// Loads the bundled JSON datasets (lazy, cached) and answers the same
/// questions the web app's lib/quran.ts + lib/mushafPages.ts answer:
/// one surah's Arabic + translation, one mushaf page's verses, and the
/// page number for a given ayah.
///
/// The English translation and the tafseer are Hafs-numbered. In Warsh
/// mode the arrays do NOT line up by position, so each Warsh verse is
/// paired with the translation/tafseer of the Hafs verse(s) with the same
/// content (via [VerseMapping]), exactly like the web app does.
class QuranRepository {
  static List<SurahMeta>? _surahs;
  static List<PageRange>? _pages;
  static Map<String, List<Ayah>>? _hafs;
  static Map<String, List<Ayah>>? _warsh;
  static Map<String, List<Ayah>>? _english;
  static Map<String, Map<String, String>>? _tafseer;

  static Future<List<SurahMeta>> surahs() async {
    if (_surahs != null) return _surahs!;
    final raw = await rootBundle.loadString('assets/data/surah_meta.json');
    final list = jsonDecode(raw) as List;
    _surahs = list
        .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _surahs!;
  }

  static Future<SurahMeta?> getMeta(int number) async {
    final all = await surahs();
    for (final s in all) {
      if (s.number == number) return s;
    }
    return null;
  }

  static Future<List<PageRange>> pages() async {
    if (_pages != null) return _pages!;
    final raw = await rootBundle.loadString('assets/data/page_mapping.json');
    final list = jsonDecode(raw) as List;
    _pages = list
        .map((e) => PageRange.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pages!;
  }

  static Future<Map<String, List<Ayah>>> _load(
      String asset, Map<String, List<Ayah>>? cache) async {
    if (cache != null) return cache;
    final raw = await rootBundle.loadString(asset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .toList()));
  }

  static Future<Map<String, List<Ayah>>> loadHafs() async {
    _hafs ??= await _load('assets/data/quran.json', _hafs);
    return _hafs!;
  }

  static Future<Map<String, List<Ayah>>> loadWarsh() async {
    _warsh ??= await _load('assets/data/warsh.json', _warsh);
    return _warsh!;
  }

  static Future<Map<String, List<Ayah>>> loadEnglish() async {
    _english ??= await _load('assets/data/en.json', _english);
    return _english!;
  }

  static Future<Map<String, Map<String, String>>> loadTafseer() async {
    if (_tafseer != null) return _tafseer!;
    final raw = await rootBundle.loadString('assets/data/tafseer.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _tafseer = decoded.map((k, v) => MapEntry(
        k, (v as Map<String, dynamic>).map((k2, v2) => MapEntry(k2, v2 as String))));
    return _tafseer!;
  }

  /// All data for one surah (Arabic + English + meta) in the given mushaf.
  static Future<SurahData> getSurah(int num, Mushaf mushaf) async {
    final meta = await getMeta(num);
    final results = await Future.wait([
      mushaf == Mushaf.warsh ? loadWarsh() : loadHafs(),
      loadEnglish(),
    ]);
    final arabicData = results[0];
    final englishData = results[1];

    final arabic = arabicData[num.toString()] ?? const <Ayah>[];
    final rawEnglish = englishData[num.toString()] ?? const <Ayah>[];

    // Pair by content in Warsh mode, not by position.
    var english = rawEnglish;
    if (mushaf == Mushaf.warsh) {
      final enByVerse = {for (final e in rawEnglish) e.verse: e.text};
      final paired = <Ayah>[];
      for (final a in arabic) {
        final hafsVerses = await VerseMapping.warshToHafs(num, a.verse);
        final parts = <String>[];
        for (final hv in hafsVerses) {
          final text = enByVerse[hv];
          if (text != null) parts.add(text);
        }
        paired.add(Ayah(
          chapter: num,
          verse: a.verse,
          text: parts.join(' '),
        ));
      }
      english = paired;
    }

    return SurahData(meta: meta, arabic: arabic, english: english);
  }

  static PageRange getPageInfo(List<PageRange> all, int pageNumber) {
    final p = pageNumber.clamp(1, 604);
    for (final x in all) {
      if (x.page == p) return x;
    }
    return all.first;
  }

  /// The verses of one mushaf page. Pages mode always renders Hafs text:
  /// the 604-page Medina Mushaf is the Hafs edition and its page mapping
  /// is Hafs-numbered (same rule as the web app's MushafPage).
  static Future<({PageRange info, List<PageVerseItem> verses})>
      getVersesForPage(int pageNumber) async {
    final all = await pages();
    final info = getPageInfo(all, pageNumber);
    final hafs = await loadHafs();
    final result = <PageVerseItem>[];
    for (var s = info.startSurah; s <= info.endSurah; s++) {
      final surahData = hafs[s.toString()] ?? const <Ayah>[];
      for (final v in surahData) {
        var inRange = false;
        if (s == info.startSurah && s == info.endSurah) {
          inRange = v.verse >= info.startAyah && v.verse <= info.endAyah;
        } else if (s == info.startSurah) {
          inRange = v.verse >= info.startAyah;
        } else if (s == info.endSurah) {
          inRange = v.verse <= info.endAyah;
        } else {
          inRange = true;
        }
        if (inRange) result.add(PageVerseItem(ayah: v, surah: s));
      }
    }
    return (info: info, verses: result);
  }

  /// The mushaf page number for a surah/ayah. Page ranges are
  /// Hafs-numbered, so a Warsh verse is converted to its first Hafs
  /// equivalent first (same rule as the web app).
  static Future<int> getPageNumberForAyah(
      int surahNumber, int ayahNumber, Mushaf mushaf) async {
    final all = await pages();
    final hafsAyah = mushaf == Mushaf.warsh
        ? (await VerseMapping.warshToHafs(surahNumber, ayahNumber)).first
        : ayahNumber;
    for (final p in all) {
      var match = false;
      if (p.startSurah == p.endSurah && p.startSurah == surahNumber) {
        match = hafsAyah >= p.startAyah && hafsAyah <= p.endAyah;
      } else if (surahNumber == p.startSurah) {
        match = hafsAyah >= p.startAyah;
      } else if (surahNumber == p.endSurah) {
        match = hafsAyah <= p.endAyah;
      } else {
        match =
            surahNumber > p.startSurah && surahNumber < p.endSurah;
      }
      if (match) return p.page;
    }
    return 1;
  }

  /// Tafseer Al-Muyassar entries for one surah, keyed to the current
  /// mushaf's verse numbers. The tafseer file is Hafs-numbered, so in
  /// Warsh mode each verse maps to its Hafs equivalent(s) first.
  static Future<List<TafseerEntry>> getTafseerForSurah(
      int surahNumber, Mushaf mushaf) async {
    final tafseer = await loadTafseer();
    final surahTafseer = tafseer[surahNumber.toString()] ?? {};
    final surahData = await getSurah(surahNumber, mushaf);
    final entries = <TafseerEntry>[];
    for (final ayah in surahData.arabic) {
      String text = '';
      if (mushaf == Mushaf.warsh) {
        final hafsVerses =
            await VerseMapping.warshToHafs(surahNumber, ayah.verse);
        final parts = <String>[];
        for (final hv in hafsVerses) {
          final t = surahTafseer[hv.toString()];
          if (t != null) parts.add(t);
        }
        text = parts.join(' ');
      } else {
        text = surahTafseer[ayah.verse.toString()] ?? '';
      }
      if (text.isNotEmpty) {
        entries.add(TafseerEntry(
            verse: ayah.verse, ayahText: ayah.text, tafseer: text));
      }
    }
    return entries;
  }
}
