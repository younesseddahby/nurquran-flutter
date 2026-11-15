import 'package:material_ui/material_ui.dart';

/// Tajweed highlighting. Direct port of src/lib/tajweedFormatter.ts.
///
/// Diacritic-based highlighting, not a full Tajweed engine: it colors what
/// the Uthmani script itself marks. Order matters — Ikhfa/Idgham run first
/// so a noon is wrapped only once, and a noon carrying any diacritic
/// (voweled, shadda, or sukoon/izhar) gets no color from those two rules.
/// Tanween-Ikhfa is NOT detectable from codepoints alone, so it is
/// intentionally left uncolored rather than guessed.
class Tajweed {
  static const Color ghunnah = Color(0xFF10B981); // green
  static const Color ikhfa = Color(0xFF14B8A6); // teal
  static const Color qalqalah = Color(0xFFEF4444); // red
  static const Color madd = Color(0xFFA855F7); // purple
  static const Color iqlab = Color(0xFFF97316); // orange

  static const _ikhfaLetters = 'تثجدذزسشصضطظفقك';
  static const _idghamGhunnahLetters = 'يومن';

  // A noon followed by no diacritic at all, then (optionally across a
  // space) an ikhfa / idgham letter.
  static final _ikhfaPattern = RegExp(
      'ن(?![\u064B-\u0652\u0670\u0653\u06E5\u06E6])(?=\\s?[$_ikhfaLetters])');
  static final _idghamPattern = RegExp(
      'ن(?![\u064B-\u0652\u0670\u0653\u06E5\u06E6])(?=\\s?[$_idghamGhunnahLetters])');
  static final _ghunnahShadda = RegExp('([نم]\u0651)');
  static final _qalqalahPattern = RegExp('([قطبجد]\u0652)');
  static final _maddPattern = RegExp('([\u0653\u0670آ\u06E5\u06E6])');
  static final _iqlabPattern = RegExp('([\u06E8\u06E2])');

  static List<InlineSpan> spans(
    String text, {
    bool enabled = true,
    required TextStyle baseStyle,
  }) {
    if (!enabled || text.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    // Collect non-overlapping colored ranges, in the same order the web
    // app applies its replacements (ikhfa, idgham, ghunnah, qalqalah,
    // madd, iqlab). A range already claimed by an earlier rule is skipped,
    // which mirrors the web version where a wrapped noon can no longer
    // match a later rule (it is followed by '<', not a letter).
    final claimed = <_Range>[];
    bool overlaps(int start, int end) =>
        claimed.any((r) => start < r.end && end > r.start);

    void collect(RegExp pattern, Color color) {
      for (final m in pattern.allMatches(text)) {
        final start = m.start;
        final end = m.end;
        if (!overlaps(start, end)) {
          claimed.add(_Range(start, end, color));
        }
      }
    }

    collect(_ikhfaPattern, ikhfa);
    collect(_idghamPattern, ghunnah);
    collect(_ghunnahShadda, ghunnah);
    collect(_qalqalahPattern, qalqalah);
    collect(_maddPattern, madd);
    collect(_iqlabPattern, iqlab);

    if (claimed.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    claimed.sort((a, b) => a.start.compareTo(b.start));
    final out = <InlineSpan>[];
    var cursor = 0;
    for (final r in claimed) {
      if (r.start > cursor) {
        out.add(TextSpan(
            text: text.substring(cursor, r.start), style: baseStyle));
      }
      out.add(TextSpan(
        text: text.substring(r.start, r.end),
        style: baseStyle.copyWith(color: r.color),
      ));
      cursor = r.end;
    }
    if (cursor < text.length) {
      out.add(
          TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    return out;
  }
}

class _Range {
  final int start;
  final int end;
  final Color color;
  const _Range(this.start, this.end, this.color);
}
