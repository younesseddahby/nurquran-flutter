import 'package:material_ui/material_ui.dart';
import 'data/quran_repository.dart';
import 'models.dart';
import 'state/app_state.dart';

/// Navigation helpers shared by all pages. They mirror the web app's
/// routing decisions: pages mode opens the mushaf at the computed page,
/// scrolling mode opens the surah page at the ayah.

void openSurah(BuildContext context, int surah, {int? ayah}) {
  Navigator.of(context).pushNamed(
    '/surah',
    arguments: {'surah': surah, if (ayah != null) 'ayah': ayah},
  );
}

Future<void> openReadingPosition(
  BuildContext context,
  AppState appState, {
  required int surah,
  required int ayah,
  Mushaf? mushaf,
}) async {
  final useMushaf = mushaf ?? appState.settings.mushaf;
  if (appState.settings.navigationStyle == NavStyle.pages) {
    // Capture the Navigator before the await: the context must not be
    // used across the async gap.
    final navigator = Navigator.of(context);
    final page = await QuranRepository.getPageNumberForAyah(
        surah, ayah, useMushaf);
    navigator.popUntil((route) => route.isFirst);
    appState.requestMushafPage(page);
  } else {
    openSurah(context, surah, ayah: ayah);
  }
}

Future<void> openSearchResult(
  BuildContext context,
  AppState appState,
  SearchResult result,
) async {
  final surah = result.number;
  if (surah == null) return;
  final ayah = result.jumpAyah ?? 1;
  await openReadingPosition(context, appState,
      surah: surah, ayah: ayah);
}

void openTafseer(BuildContext context, int surah, {int? ayah}) {
  Navigator.of(context).pushNamed(
    '/tafseer/$surah',
    arguments: ayah,
  );
}
