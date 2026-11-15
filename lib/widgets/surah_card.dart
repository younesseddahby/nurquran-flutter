import 'package:material_ui/material_ui.dart';
import '../models.dart';
import '../theme.dart';

/// One surah row/card. Mirrors SurahCard.tsx: number in an ornamental
/// frame, Arabic name, English name, revelation + ayah count.
class SurahCard extends StatelessWidget {
  final SurahMeta surah;
  final bool isArabicUi;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.isArabicUi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '${surah.number}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabicUi ? surah.arabicName : surah.name,
                    style: TextStyle(
                      fontFamily:
                          isArabicUi ? NurTheme.arabicFont : null,
                      fontSize: isArabicUi ? 20 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabicUi
                        ? '${surah.englishName} · ${surah.ayahs} آيات'
                        : '${surah.englishName} · ${surah.ayahs} verses',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              surah.arabicName,
              style: const TextStyle(
                fontFamily: NurTheme.arabicFont,
                fontSize: 22,
                color: NurTheme.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
