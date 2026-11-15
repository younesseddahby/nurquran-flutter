import '../models.dart';
import 'quran_repository.dart';
import 'verse_mapping.dart';

/// Advanced Quran Search Engine (V3.2) — direct port of src/lib/search.ts.
/// Dual-level normalization for Hafs and Warsh; exact phrases, spelling
/// variations, surah names, verse references (2:255, Baqarah 255), and
/// English translation keywords.

String normalizeArabicExact(String text) {
  if (text.isEmpty) return '';
  var out = text
      .replaceAll(
          RegExp(
              r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u06E0-\u06E9۞ۖۗۚۛۦ۪ۭۧۨ۫۬ۮ]'),
          '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll(RegExp(r'ؤ'), 'و')
      .replaceAll(RegExp(r'[ئىےی]'), 'ي')
      .replaceAll(RegExp(r'ة'), 'ه')
      .replaceAll(RegExp(r'ـ'), '')
      .replaceAll(RegExp(r'ء'), '')
      .replaceAll(RegExp(r'ا+'), 'ا')
      .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return out;
}

String normalizeArabicFlex(String text) {
  if (text.isEmpty) return '';
  return normalizeArabicExact(text).replaceAll(RegExp(r'ا'), '');
}

String normalizeLatin(String text) {
  return text.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
}


T? _firstOrNull<T>(Iterable<T> it) => it.isEmpty ? null : it.first;

class _SearchEngine {
  final Map<String, String> _normExact = {};
  final Map<String, String> _normFlex = {};

  (String, String) _ayahNorms(
      String sn, int verse, String text, Mushaf mushaf) {
    final key = '${mushaf.key}-$sn-$verse';
    final cachedExact = _normExact[key];
    if (cachedExact != null) return (cachedExact, _normFlex[key]!);
    final exact = normalizeArabicExact(text);
    final flex = normalizeArabicFlex(text);
    _normExact[key] = exact;
    _normFlex[key] = flex;
    return (exact, flex);
  }

  Future<List<SearchResult>> advancedSearch(
      String query, Mushaf mushaf) async {
    var rawQ = query.trim();
    if (rawQ.length < 2) return [];

    rawQ = rawQ.replaceAll(RegExp(r'^(سورة|سوره|surah|sura)\s+',
        caseSensitive: false), '');
    final lowerQ = rawQ.toLowerCase();
    final normLatinQ = normalizeLatin(lowerQ);
    final normArExactQ = normalizeArabicExact(rawQ);
    final normArFlexQ = normalizeArabicFlex(rawQ);

    final queryTokensExact =
        normArExactQ.split(' ').where((t) => t.isNotEmpty).toList();
    final queryTokensFlex =
        normArFlexQ.split(' ').where((t) => t.isNotEmpty).toList();

    final isArabicSearch = RegExp(r'[\u0600-\u06FF]').hasMatch(rawQ);

    final arabicData = mushaf == Mushaf.warsh
        ? await QuranRepository.loadWarsh()
        : await QuranRepository.loadHafs();
    final englishData = await QuranRepository.loadEnglish();
    final surahMeta = await QuranRepository.surahs();

    final results = <SearchResult>[];

    // --- PHASE 1: EXACT REFERENCE (e.g. 2:255 or Baqarah 255) ---
    final refMatch = RegExp(r'^(\d+)[\s:-]+(\d+)$').firstMatch(lowerQ);
    if (refMatch != null) {
      final sNum = int.parse(refMatch.group(1)!);
      final aNum = int.parse(refMatch.group(2)!);
      if (sNum >= 1 && sNum <= 114) {
        final meta = _firstOrNull(
            surahMeta.where((s) => s.number == sNum));
        // Bound by the CURRENT mushaf's verse count, not the Hafs-based
        // meta: Warsh counts differ (e.g. Baqarah 285, not 286).
        final surahLength = arabicData[sNum.toString()]?.length ?? 0;
        if (meta != null && aNum <= surahLength) {
          final ayah = arabicData[sNum.toString()]![aNum - 1];
          results.add(SearchResult(
            id: 'ref-$sNum-$aNum',
            type: SearchResultType.reference,
            number: meta.number,
            name: meta.name,
            englishName: meta.englishName,
            arabicName: meta.arabicName,
            revelation: meta.revelation,
            jumpAyah: aNum,
            preview: ayah.text,
            score: 100000,
          ));
        }
      }
    } else {
      final nameRefMatch = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(lowerQ);
      if (nameRefMatch != null) {
        final inputName = nameRefMatch.group(1)!.trim();
        final aNum = int.parse(nameRefMatch.group(2)!);
        final normInputNameAr = normalizeArabicExact(inputName);
        final normInputNameLat = normalizeLatin(inputName);
        final foundSurah = _firstOrNull(surahMeta.where((s) =>
            normalizeArabicExact(s.arabicName) == normInputNameAr ||
            normalizeLatin(s.name) == normInputNameLat ||
            normalizeLatin(s.englishName) == normInputNameLat));
        final foundSurahLength = foundSurah == null
            ? 0
            : arabicData[foundSurah.number.toString()]?.length ?? 0;
        if (foundSurah != null && aNum <= foundSurahLength) {
          final ayah =
              arabicData[foundSurah.number.toString()]![aNum - 1];
          results.add(SearchResult(
            id: 'ref-name-${foundSurah.number}-$aNum',
            type: SearchResultType.reference,
            number: foundSurah.number,
            name: foundSurah.name,
            englishName: foundSurah.englishName,
            arabicName: foundSurah.arabicName,
            revelation: foundSurah.revelation,
            jumpAyah: aNum,
            preview: ayah.text,
            score: 100000,
          ));
        }
      }
    }

    // --- PHASE 2: SURAH NAME MATCHING ---
    for (final s in surahMeta) {
      final sNormLatin = normalizeLatin(s.name);
      final sNormAr = normalizeArabicExact(s.arabicName);
      final sEnName = normalizeLatin(s.englishName);
      var score = 0;
      if (sNormLatin == normLatinQ ||
          sNormAr == normArExactQ ||
          sEnName == normLatinQ) {
        score = 80000;
      } else if (s.number.toString() == rawQ) {
        score = 75000;
      } else if (normLatinQ.length >= 3 &&
          (sNormLatin.startsWith(normLatinQ) ||
              sEnName.startsWith(normLatinQ))) {
        score = 15000;
      } else if (normArExactQ.length >= 3 &&
          sNormAr.startsWith(normArExactQ)) {
        score = 15000;
      } else if (normLatinQ.length >= 4 &&
          sNormLatin.contains(normLatinQ)) {
        score = 2000;
      } else if (normArExactQ.length >= 4 &&
          sNormAr.contains(normArExactQ)) {
        score = 2000;
      }
      if (isArabicSearch && normArExactQ.length > 8 && score < 50000) {
        score = score ~/ 10;
      }
      if (score > 0) {
        results.add(SearchResult(
          id: 'surah-${s.number}',
          type: SearchResultType.surah,
          number: s.number,
          name: s.name,
          englishName: s.englishName,
          arabicName: s.arabicName,
          revelation: s.revelation,
          preview: s.englishName,
          score: score,
        ));
      }
    }

    // --- PHASE 3: QURAN TEXT SEARCH (ARABIC) ---
    if (normArExactQ.length >= 2) {
      for (final sn in arabicData.keys) {
        final sNum = int.parse(sn);
        final currentSurahMeta =
            _firstOrNull(surahMeta.where((s) => s.number == sNum));
        if (currentSurahMeta == null) continue;
        for (final v in arabicData[sn]!) {
          final (exact, flex) = _ayahNorms(sn, v.verse, v.text, mushaf);
          var score = 0;
          if (exact == normArExactQ || flex == normArFlexQ) {
            score = 50000;
          } else if (exact.contains(normArExactQ)) {
            score = 30000 + (normArExactQ.length * 10);
          } else if (normArFlexQ.length >= 3 &&
              flex.contains(normArFlexQ)) {
            score = 25000 + (normArFlexQ.length * 10);
          } else if (queryTokensExact.length > 1) {
            var matchesCount = 0;
            for (var i = 0; i < queryTokensExact.length; i++) {
              final tokExact = queryTokensExact[i];
              final tokFlex = i < queryTokensFlex.length
                  ? queryTokensFlex[i]
                  : tokExact;
              if (exact.contains(tokExact) ||
                  (tokFlex.length >= 2 && flex.contains(tokFlex))) {
                matchesCount++;
              }
            }
            if (matchesCount == queryTokensExact.length) {
              score = 20000 + (matchesCount * 100);
            } else if (matchesCount >=
                (queryTokensExact.length * 0.7).ceil()) {
              score = 8000 + (matchesCount * 100);
            }
          }
          if (score > 0) {
            results.add(SearchResult(
              id: 'ayah-$sn-${v.verse}',
              type: SearchResultType.ayah,
              number: currentSurahMeta.number,
              name: currentSurahMeta.name,
              englishName: currentSurahMeta.englishName,
              arabicName: currentSurahMeta.arabicName,
              revelation: currentSurahMeta.revelation,
              jumpAyah: v.verse,
              preview: v.text,
              score: score,
              mushaf: mushaf,
            ));
          }
        }
        if (results.length > 200) break;
      }
    }

    // --- PHASE 4: TRANSLATION SEARCH ---
    if (!isArabicSearch && normLatinQ.length >= 4 && results.length < 3) {
      var transCount = 0;
      for (final sn in englishData.keys) {
        final sNum = int.parse(sn);
        final currentSurahMeta =
            _firstOrNull(surahMeta.where((s) => s.number == sNum));
        if (currentSurahMeta == null) continue;
        for (final v in englishData[sn]!) {
          final lowerTrans = v.text.toLowerCase();
          if (lowerTrans.contains(normLatinQ)) {
            // The translation file is Hafs-numbered. In Warsh mode the
            // jump target must be converted to the Warsh verse with the
            // same content; a Hafs verse with no Warsh equivalent (only
            // Fatiha's Bismillah) is skipped.
            final targetAyah = mushaf == Mushaf.warsh
                ? await VerseMapping.hafsToWarsh(sNum, v.verse)
                : v.verse;
            if (targetAyah == null) continue;
            results.add(SearchResult(
              id: 'trans-$sn-${v.verse}',
              type: SearchResultType.translation,
              number: currentSurahMeta.number,
              name: currentSurahMeta.name,
              englishName: currentSurahMeta.englishName,
              arabicName: currentSurahMeta.arabicName,
              revelation: currentSurahMeta.revelation,
              jumpAyah: targetAyah,
              preview: v.text,
              score: 5000 + normLatinQ.length,
            ));
            transCount++;
          }
          if (transCount >= 5) break;
        }
        if (transCount >= 5) break;
      }
    }

    // --- FINAL FILTERING ---
    final sorted = results..sort((a, b) => b.score.compareTo(a.score));
    final bestScore = sorted.isEmpty ? 0 : sorted.first.score;
    final finalResults = <SearchResult>[];
    final seen = <String>{};
    for (final r in sorted) {
      final key = '${r.number}-${r.jumpAyah ?? 0}';
      if (seen.contains(key)) continue;
      if (bestScore >= 80000 && r.score < 70000) continue;
      if (bestScore >= 50000 && r.score < 20000) continue;
      seen.add(key);
      finalResults.add(r);
      if (finalResults.length >= 15) break;
    }
    return finalResults;
  }
}

/// Shared engine instance (keeps the normalization cache warm across
/// searches, like the web app's module-level caches).
final _engine = _SearchEngine();

Future<List<SearchResult>> advancedSearch(String query, Mushaf mushaf) =>
    _engine.advancedSearch(query, mushaf);
