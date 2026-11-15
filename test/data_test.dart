import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nur_quran/data/quran_repository.dart';
import 'package:nur_quran/data/search.dart';
import 'package:nur_quran/data/tajweed.dart';
import 'package:nur_quran/data/verse_mapping.dart';
import 'package:nur_quran/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('surah metadata: 114 surahs', () async {
    final surahs = await QuranRepository.surahs();
    expect(surahs.length, 114);
    expect(surahs.first.arabicName, 'الفاتحة');
    expect(surahs.last.number, 114);
  });

  test('page mapping: 604 pages, page 1 is Fatiha', () async {
    final pages = await QuranRepository.pages();
    expect(pages.length, 604);
    final page1 = await QuranRepository.getVersesForPage(1);
    expect(page1.info.page, 1);
    expect(page1.verses.length, 7);
    expect(page1.verses.first.surah, 1);
    expect(page1.verses.first.ayah.verse, 1);
  });

  test('verse counts: Warsh 6214 / Hafs 6236; Baqarah 285 vs 286', () async {
    final warsh = await QuranRepository.getSurah(2, Mushaf.warsh);
    final hafs = await QuranRepository.getSurah(2, Mushaf.hafs);
    expect(warsh.arabic.length, 285);
    expect(hafs.arabic.length, 286);
    final warshAll = await QuranRepository.loadWarsh();
    final totalWarsh =
        warshAll.values.fold<int>(0, (sum, list) => sum + list.length);
    expect(totalWarsh, 6214);
    final hafsAll = await QuranRepository.loadHafs();
    final totalHafs =
        hafsAll.values.fold<int>(0, (sum, list) => sum + list.length);
    expect(totalHafs, 6236);
  });

  test('warsh -> hafs mapping', () async {
    // Warsh Fatiha 1:1 ("Alhamdu...") is Hafs 1:2 (Hafs counts Bismillah).
    expect(await VerseMapping.warshToHafs(1, 1), [2]);
    // Warsh 2:1 joins Hafs 2:1 + 2:2.
    expect(await VerseMapping.warshToHafs(2, 1), [1, 2]);
    // Warsh 2:2 is Hafs 2:3.
    expect(await VerseMapping.warshToHafs(2, 2), [3]);
    // Hafs 1:1 (Bismillah) has no Warsh equivalent.
    expect(await VerseMapping.hafsToWarsh(1, 1), isNull);
    // Identical surah maps to itself.
    expect(await VerseMapping.warshToHafs(112, 1), [1]);
  });

  test('page number for Ayat al-Kursi contains 2:255', () async {
    final page =
        await QuranRepository.getPageNumberForAyah(2, 255, Mushaf.hafs);
    final all = await QuranRepository.pages();
    final info = QuranRepository.getPageInfo(all, page);
    expect(info.startSurah, 2);
    expect(info.startAyah, lessThanOrEqualTo(255));
    expect(info.endAyah, greaterThanOrEqualTo(255));
  });

  test('translation pairs by content in Warsh mode', () async {
    final warsh = await QuranRepository.getSurah(2, Mushaf.warsh);
    // Warsh 2:2's translation must be Hafs 2:3's ("who believe in the
    // unseen"), not Hafs 2:2's ("This is the Book...").
    final second = warsh.english[1];
    expect(second.text.toLowerCase(), contains('unseen'));
    expect(second.text.toLowerCase(), isNot(contains('this is the book')));
  });

  test('search: surah name, reference, ayah text', () async {
    final byName = await advancedSearch('الفاتحة', Mushaf.hafs);
    expect(byName, isNotEmpty);
    expect(byName.first.type, SearchResultType.surah);
    expect(byName.first.number, 1);

    final byRef = await advancedSearch('2:255', Mushaf.hafs);
    expect(byRef, isNotEmpty);
    expect(byRef.first.type, SearchResultType.reference);
    expect(byRef.first.number, 2);
    expect(byRef.first.jumpAyah, 255);

    final byText = await advancedSearch('الحمد لله رب العالمين', Mushaf.hafs);
    expect(byText.any((r) => r.number == 1 && r.jumpAyah == 2), isTrue);
  });

  test('tajweed: noon before an ikhfa letter is colored', () {
    const base = TextStyle(fontSize: 20);
    final spans = Tajweed.spans('من قبل', baseStyle: base);
    var foundIkhfa = false;
    for (final span in spans) {
      if (span is TextSpan &&
          span.text == 'ن' &&
          span.style?.color == Tajweed.ikhfa) {
        foundIkhfa = true;
      }
    }
    expect(foundIkhfa, isTrue);
  });

  test('tajweed: shadda noon is ghunnah', () {
    const base = TextStyle(fontSize: 20);
    // noon + shadda + fatha, in canonical Uthmani order.
    final spans =
        Tajweed.spans('\u0625\u0650\u0646\u0651\u064E', baseStyle: base);
    var foundGhunnah = false;
    for (final span in spans) {
      if (span is TextSpan && span.style?.color == Tajweed.ghunnah) {
        foundGhunnah = true;
      }
    }
    expect(foundGhunnah, isTrue);
  });

  test('tafseer loads for a surah', () async {
    final entries =
        await QuranRepository.getTafseerForSurah(1, Mushaf.hafs);
    expect(entries.length, 7);
    expect(entries.first.tafseer, isNotEmpty);
  });
}
