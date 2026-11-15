import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../data/quran_repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';

/// Bottom sheet for ayah actions. Mirrors AyahActionMenu.tsx:
/// Tafseer (Arabic UI only), bookmark toggle, native share sheet.
/// Share text format is identical to the web app's.
Future<void> showAyahActionSheet(
  BuildContext context, {
  required AppState appState,
  required int surahNumber,
  required int ayahNumber,
  required String ayahText,
  String? translationText,
  // Pages mode always shows Hafs text, so bookmarks/progress saved from
  // there are stamped Hafs even when the user reads Warsh elsewhere.
  Mushaf? mushafOverride,
}) async {
  final settings = appState.settings;
  final effectiveMushaf = mushafOverride ?? settings.mushaf;
  final s = settings.isArabic ? S.arabic : S.english;
  final meta = await QuranRepository.getMeta(surahNumber);
  final isBookmarked = appState.isBookmarked(surahNumber, ayahNumber);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$ayahNumber',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.surah.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.isArabic
                              ? (meta?.arabicName ?? '')
                              : (meta?.name ?? ''),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (settings.isArabic)
                _ActionButton(
                  icon: Icons.message_outlined,
                  label: s.showTafseer,
                  filled: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed(
                      '/tafseer/$surahNumber',
                      arguments: ayahNumber,
                    );
                  },
                ),
              _ActionButton(
                icon: isBookmarked
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
                label: isBookmarked ? s.removeAyah : s.saveAyah,
                highlighted: isBookmarked,
                onTap: () async {
                  final previewSource =
                      translationText?.isNotEmpty == true
                          ? translationText!
                          : ayahText;
                  await appState.toggleBookmark(Bookmark(
                    surah: surahNumber,
                    ayah: ayahNumber,
                    mushaf: effectiveMushaf,
                    preview: previewSource.length > 80
                        ? previewSource.substring(0, 80)
                        : previewSource,
                  ));
                  await appState.saveProgress(Progress(
                    surah: surahNumber,
                    ayah: ayahNumber,
                    mushaf: effectiveMushaf,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  ));
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: s.shareAyah,
                onTap: () async {
                  final isArDir = settings.isArabic;
                  final surahName =
                      isArDir ? meta?.arabicName : meta?.name;
                  final surahPrefix = isArDir ? 'سورة' : 'Surah';
                  final ayahLabel = isArDir ? 'الآية' : 'Ayah';
                  final shareText =
                      '$ayahText\n\n$surahPrefix $surahName — $ayahLabel $ayahNumber\nنور القرآن';
                  Navigator.of(sheetContext).pop();
                  await Share.share(shareText, subject: s.shareTitle);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool highlighted;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.filled = false,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: filled
                ? scheme.primary
                : highlighted
                    ? NurTheme.gold.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: highlighted
                ? Border.all(color: NurTheme.gold.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.2)
                      : highlighted
                          ? NurTheme.gold.withValues(alpha: 0.2)
                          : scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: filled
                      ? scheme.onPrimary
                      : highlighted
                          ? NurTheme.gold
                          : scheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: filled
                      ? scheme.onPrimary
                      : highlighted
                          ? NurTheme.gold
                          : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
