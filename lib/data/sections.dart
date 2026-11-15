import '../models.dart';
import 'quran_repository.dart';

/// Juz / Hizb start positions, per mushaf. Direct port of
/// src/lib/quranSections.ts (the fixed Warsh table from the Oct 2026
/// hizb fix — Warsh hizb boundaries differ from Hafs in several places).
/// Each entry: hizb number -> [surah, ayah] it starts at.
class Sections {
  static const Map<int, List<int>> _hafsHizbs = {
    1: [1, 1], 2: [2, 76], 3: [2, 142], 4: [2, 203], 5: [2, 253],
    6: [3, 15], 7: [3, 92], 8: [3, 171], 9: [4, 24], 10: [4, 87],
    11: [4, 148], 12: [5, 23], 13: [5, 82], 14: [6, 36], 15: [6, 111],
    16: [7, 5], 17: [7, 88], 18: [7, 171], 19: [8, 41], 20: [9, 34],
    21: [9, 93], 22: [10, 26], 23: [11, 6], 24: [11, 84], 25: [12, 53],
    26: [13, 19], 27: [15, 1], 28: [16, 51], 29: [17, 1], 30: [17, 99],
    31: [18, 75], 32: [20, 1], 33: [21, 1], 34: [22, 1], 35: [23, 1],
    36: [24, 21], 37: [25, 21], 38: [26, 111], 39: [27, 56], 40: [28, 51],
    41: [29, 46], 42: [31, 22], 43: [33, 31], 44: [34, 24], 45: [36, 28],
    46: [37, 145], 47: [39, 32], 48: [40, 41], 49: [41, 47], 50: [43, 24],
    51: [46, 1], 52: [48, 18], 53: [51, 31], 54: [55, 1], 55: [58, 1],
    56: [61, 1], 57: [67, 1], 58: [72, 1], 59: [78, 1], 60: [87, 1],
  };

  static const Map<int, List<int>> _warshHizbs = {
    1: [1, 1], 2: [2, 75], 3: [2, 141], 4: [2, 201], 5: [2, 251],
    6: [3, 15], 7: [3, 91], 8: [3, 171], 9: [4, 24], 10: [4, 86],
    11: [4, 147], 12: [5, 25], 13: [5, 84], 14: [6, 37], 15: [6, 112],
    16: [7, 4], 17: [7, 87], 18: [7, 171], 19: [8, 41], 20: [9, 34],
    21: [9, 94], 22: [10, 26], 23: [11, 6], 24: [11, 83], 25: [12, 53],
    26: [13, 21], 27: [15, 1], 28: [16, 51], 29: [17, 1], 30: [17, 99],
    31: [18, 74], 32: [20, 1], 33: [21, 1], 34: [22, 1], 35: [23, 1],
    36: [24, 21], 37: [25, 21], 38: [26, 111], 39: [27, 58], 40: [28, 51],
    41: [29, 46], 42: [31, 21], 43: [33, 31], 44: [34, 24], 45: [36, 27],
    46: [37, 145], 47: [39, 31], 48: [40, 41], 49: [41, 46], 50: [43, 23],
    51: [46, 1], 52: [48, 18], 53: [51, 31], 54: [55, 1], 55: [58, 1],
    56: [62, 1], 57: [67, 1], 58: [72, 1], 59: [78, 1], 60: [87, 1],
  };

  static Future<List<HizbInfo>> getHizbList(Mushaf mushaf) async {
    final map = mushaf == Mushaf.warsh ? _warshHizbs : _hafsHizbs;
    final list = <HizbInfo>[];
    for (var h = 1; h <= 60; h++) {
      final pos = map[h]!;
      final meta = await QuranRepository.getMeta(pos[0]);
      list.add(HizbInfo(
        hizbNumber: h,
        juzNumber: (h / 2).ceil(),
        surahNumber: pos[0],
        ayahNumber: pos[1],
        surahName: meta?.name ?? '',
        surahArabicName: meta?.arabicName ?? '',
      ));
    }
    return list;
  }

  static Future<List<JuzInfo>> getJuzList(Mushaf mushaf) async {
    final hizbs = await getHizbList(mushaf);
    final list = <JuzInfo>[];
    for (var j = 1; j <= 30; j++) {
      final startHizbNum = (j - 1) * 2 + 1;
      final startHizb =
          hizbs.firstWhere((h) => h.hizbNumber == startHizbNum);
      list.add(JuzInfo(
        juzNumber: j,
        startHizb: startHizbNum,
        endHizb: startHizbNum + 1,
        surahNumber: startHizb.surahNumber,
        ayahNumber: startHizb.ayahNumber,
        surahName: startHizb.surahName,
        surahArabicName: startHizb.surahArabicName,
      ));
    }
    return list;
  }
}
