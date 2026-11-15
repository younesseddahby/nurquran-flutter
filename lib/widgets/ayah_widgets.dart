import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import '../data/tajweed.dart';
import '../models.dart';
import '../theme.dart';

/// Ornamental 8-point star frame with the ayah number inside.
/// Gold when bookmarked — same rule as the web app's AyahNumber.
class AyahNumberBadge extends StatelessWidget {
  final int number;
  final bool isBookmarked;
  final double size;

  const AyahNumberBadge({
    super.key,
    required this.number,
    required this.isBookmarked,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBookmarked
        ? NurTheme.gold
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.45);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _StarPainter(color: color),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.bold,
              color: isBookmarked
                  ? NurTheme.gold
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// 8-point star outline (two squares rotated 45°).
class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    Path square(double rotation) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rotation + i * math.pi / 2;
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    }

    canvas.drawPath(square(-math.pi / 4), paint);
    canvas.drawPath(square(0), paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}

/// Hizb marker: gold star with "حزب" + number. Mirrors Marker.tsx.
class HizbMarkerWidget extends StatelessWidget {
  final int number;
  const HizbMarkerWidget({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(
            size: Size(42, 42),
            painter: _StarPainter(color: NurTheme.gold),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'حزب',
                style: TextStyle(
                  fontFamily: NurTheme.arabicFont,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: NurTheme.gold,
                  height: 1,
                ),
              ),
              Text(
                '$number',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: NurTheme.gold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Bismillah line shown before each surah (except 9 and 1).
class BismillahWidget extends StatelessWidget {
  const BismillahWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Text(
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: NurTheme.arabicFont,
          fontSize: 28,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// One ayah's text as rich spans (tajweed colors when enabled).
List<InlineSpan> ayahSpans(
  String text, {
  required TextStyle baseStyle,
  required bool showTajweed,
}) =>
    Tajweed.spans(text, enabled: showTajweed, baseStyle: baseStyle);

/// Flowing Arabic text for a whole surah or a whole mushaf page:
/// ayahs in one justified RTL paragraph, each tappable, with hizb
/// markers, Bismillah blocks and ayah-number badges inline.
/// Mirrors SurahArabicOnly.tsx / MushafPage.tsx.
class FlowingAyahText extends StatefulWidget {
  final List<({Ayah ayah, int surah})> items;
  final bool showBismillah;
  final double fontSize;
  final bool showTajweed;
  final bool Function(int surah, int ayah) isBookmarked;
  final void Function(int surah, int ayah) onAyahTap;

  const FlowingAyahText({
    super.key,
    required this.items,
    this.showBismillah = true,
    required this.fontSize,
    required this.showTajweed,
    required this.isBookmarked,
    required this.onAyahTap,
  });

  @override
  State<FlowingAyahText> createState() => _FlowingAyahTextState();
}

class _FlowingAyahTextState extends State<FlowingAyahText> {
  final Map<String, TapGestureRecognizer> _recognizers = {};

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(int surah, int ayah) {
    final key = '$surah-$ayah';
    return _recognizers.putIfAbsent(key, () {
      final r = TapGestureRecognizer();
      r.onTap = () => widget.onAyahTap(surah, ayah);
      return r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: NurTheme.arabicFont,
      fontSize: widget.fontSize,
      height: 2.7,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final spans = <InlineSpan>[];
    var first = true;
    var currentSurah = -1;

    for (final item in widget.items) {
      final ayah = item.ayah;
      final surah = item.surah;

      // Bismillah at the start of a new surah (except 9 and 1).
      if (surah != currentSurah) {
        currentSurah = surah;
        if (widget.showBismillah && ayah.verse == 1 && surah != 9 && surah != 1) {
          spans.add(const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: BismillahWidget(),
          ));
          first = true;
        }
      }

      if (!first) spans.add(const TextSpan(text: ' '));
      first = false;

      if (ayah.structural == 'hizb' && ayah.hizb != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: HizbMarkerWidget(number: ayah.hizb!),
          ),
        ));
        spans.add(const TextSpan(text: ' '));
      }

      final recognizer = _recognizerFor(surah, ayah.verse);
      for (final s in ayahSpans(ayah.text,
          baseStyle: baseStyle, showTajweed: widget.showTajweed)) {
        if (s is TextSpan) {
          spans.add(TextSpan(
              text: s.text, style: s.style, recognizer: recognizer));
        } else {
          spans.add(s);
        }
      }

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => widget.onAyahTap(surah, ayah.verse),
            child: AyahNumberBadge(
              number: ayah.verse,
              isBookmarked: widget.isBookmarked(surah, ayah.verse),
              size: 34,
            ),
          ),
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
