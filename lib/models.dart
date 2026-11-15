// Data models for Nur Quran (Flutter).
// Mirrors src/lib/types.ts + src/data structures of the Capacitor app.

enum Mushaf { hafs, warsh }

extension MushafName on Mushaf {
  String get key => name;
  static Mushaf fromKey(String? key) =>
      key == 'warsh' ? Mushaf.warsh : Mushaf.hafs;
}

class SurahMeta {
  final int number;
  final String name;
  final String englishName;
  final String arabicName;
  final String revelation; // 'Meccan' | 'Medinan'
  final int ayahs;

  const SurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.arabicName,
    required this.revelation,
    required this.ayahs,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> j) => SurahMeta(
        number: j['number'] as int,
        name: j['name'] as String,
        englishName: j['englishName'] as String,
        arabicName: j['arabicName'] as String,
        revelation: j['revelation'] as String,
        ayahs: j['ayahs'] as int,
      );
}

class Ayah {
  final int chapter;
  final int verse;
  final int? juz;
  final int? hizb;
  final bool? sajda;
  final String? structural; // e.g. 'hizb'
  final String text;
  final String? textEmlaey;

  const Ayah({
    required this.chapter,
    required this.verse,
    this.juz,
    this.hizb,
    this.sajda,
    this.structural,
    required this.text,
    this.textEmlaey,
  });

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
        chapter: j['chapter'] as int,
        verse: j['verse'] as int,
        juz: j['juz'] as int?,
        hizb: j['hizb'] as int?,
        sajda: j['sajda'] as bool?,
        structural: j['structural'] as String?,
        text: j['text'] as String,
        textEmlaey: j['text_emlaey'] as String?,
      );
}

class PageRange {
  final int page;
  final int juz;
  final int hizb;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  const PageRange({
    required this.page,
    required this.juz,
    required this.hizb,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  factory PageRange.fromJson(Map<String, dynamic> j) => PageRange(
        page: j['page'] as int,
        juz: j['juz'] as int,
        hizb: j['hizb'] as int,
        startSurah: j['startSurah'] as int,
        startAyah: j['startAyah'] as int,
        endSurah: j['endSurah'] as int,
        endAyah: j['endAyah'] as int,
      );
}

class PageVerseItem {
  final Ayah ayah;
  final int surah;
  const PageVerseItem({required this.ayah, required this.surah});
}

class Bookmark {
  final int surah;
  final int ayah;
  final String preview;
  final Mushaf? mushaf; // riwaya it was saved in; verse numbers differ
  final int? createdAt;

  const Bookmark({
    required this.surah,
    required this.ayah,
    required this.preview,
    this.mushaf,
    this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        surah: j['surah'] as int,
        ayah: j['ayah'] as int,
        preview: j['preview'] as String? ?? '',
        mushaf: j['mushaf'] == null
            ? null
            : MushafName.fromKey(j['mushaf'] as String),
        createdAt: j['createdAt'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'preview': preview,
        if (mushaf != null) 'mushaf': mushaf!.key,
        if (createdAt != null) 'createdAt': createdAt,
      };
}

class Progress {
  final int surah;
  final int ayah;
  final int? updatedAt;
  final Mushaf? mushaf;

  const Progress({
    required this.surah,
    required this.ayah,
    this.updatedAt,
    this.mushaf,
  });

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        surah: j['surah'] as int,
        ayah: j['ayah'] as int,
        updatedAt: j['updatedAt'] as int?,
        mushaf: j['mushaf'] == null
            ? null
            : MushafName.fromKey(j['mushaf'] as String),
      );

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (mushaf != null) 'mushaf': mushaf!.key,
      };
}

enum NavStyle { pages, scrolling }

extension NavStyleName on NavStyle {
  String get key => name;
  static NavStyle fromKey(String? key) =>
      key == 'pages' ? NavStyle.pages : NavStyle.scrolling;
}

class AppSettings {
  final String language; // 'arabic' | 'english'
  final double arabicSize;
  final double translationSize;
  final bool showTranslation;
  final String theme; // 'light' | 'dark'
  final String colorTheme; // 'emerald' (only theme shipped in the web app)
  final Mushaf mushaf;
  final NavStyle navigationStyle;
  final bool showTajweed;

  const AppSettings({
    required this.language,
    required this.arabicSize,
    required this.translationSize,
    required this.showTranslation,
    required this.theme,
    required this.colorTheme,
    required this.mushaf,
    required this.navigationStyle,
    required this.showTajweed,
  });

  static const defaults = AppSettings(
    language: 'arabic',
    arabicSize: 20,
    translationSize: 16,
    showTranslation: true,
    theme: 'light',
    colorTheme: 'emerald',
    mushaf: Mushaf.warsh,
    navigationStyle: NavStyle.scrolling,
    showTajweed: true,
  );

  bool get isArabic => language == 'arabic';
  bool get isDark => theme == 'dark';

  AppSettings copyWith({
    String? language,
    double? arabicSize,
    double? translationSize,
    bool? showTranslation,
    String? theme,
    String? colorTheme,
    Mushaf? mushaf,
    NavStyle? navigationStyle,
    bool? showTajweed,
  }) =>
      AppSettings(
        language: language ?? this.language,
        arabicSize: arabicSize ?? this.arabicSize,
        translationSize: translationSize ?? this.translationSize,
        showTranslation: showTranslation ?? this.showTranslation,
        theme: theme ?? this.theme,
        colorTheme: colorTheme ?? this.colorTheme,
        mushaf: mushaf ?? this.mushaf,
        navigationStyle: navigationStyle ?? this.navigationStyle,
        showTajweed: showTajweed ?? this.showTajweed,
      );

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings.defaults;
    return AppSettings(
      language: j['language'] as String? ?? d.language,
      arabicSize: (j['arabicSize'] as num?)?.toDouble() ?? d.arabicSize,
      translationSize:
          (j['translationSize'] as num?)?.toDouble() ?? d.translationSize,
      showTranslation: j['showTranslation'] as bool? ?? d.showTranslation,
      theme: j['theme'] as String? ?? d.theme,
      colorTheme: j['colorTheme'] as String? ?? d.colorTheme,
      mushaf: MushafName.fromKey(j['mushaf'] as String?),
      navigationStyle: NavStyleName.fromKey(j['navigationStyle'] as String?),
      showTajweed: j['showTajweed'] as bool? ?? d.showTajweed,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'arabicSize': arabicSize,
        'translationSize': translationSize,
        'showTranslation': showTranslation,
        'theme': theme,
        'colorTheme': colorTheme,
        'mushaf': mushaf.key,
        'navigationStyle': navigationStyle.key,
        'showTajweed': showTajweed,
      };
}

class HizbInfo {
  final int hizbNumber;
  final int juzNumber;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String surahArabicName;

  const HizbInfo({
    required this.hizbNumber,
    required this.juzNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.surahArabicName,
  });
}

class JuzInfo {
  final int juzNumber;
  final int startHizb;
  final int endHizb;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String surahArabicName;

  const JuzInfo({
    required this.juzNumber,
    required this.startHizb,
    required this.endHizb,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.surahArabicName,
  });
}

enum SearchResultType { surah, ayah, reference, translation }

class SearchResult {
  final String id;
  final SearchResultType type;
  final int? number; // surah number
  final String? name;
  final String? englishName;
  final String? arabicName;
  final String? revelation;
  final int? jumpAyah;
  final String preview;
  final int score;
  final Mushaf? mushaf;

  const SearchResult({
    required this.id,
    required this.type,
    this.number,
    this.name,
    this.englishName,
    this.arabicName,
    this.revelation,
    this.jumpAyah,
    required this.preview,
    required this.score,
    this.mushaf,
  });
}

/// One surah's Arabic + English (translation) data, as returned by
/// getSurah — mirrors the web app's getSurah() return shape.
class SurahData {
  final SurahMeta? meta;
  final List<Ayah> arabic;
  final List<Ayah> english; // same length/order as arabic; text = translation

  const SurahData({
    required this.meta,
    required this.arabic,
    required this.english,
  });
}

/// One tafseer entry: the ayah (in the current mushaf's numbering) + its
/// Tafseer Al-Muyassar text.
class TafseerEntry {
  final int verse;
  final String ayahText;
  final String tafseer;

  const TafseerEntry({
    required this.verse,
    required this.ayahText,
    required this.tafseer,
  });
}
