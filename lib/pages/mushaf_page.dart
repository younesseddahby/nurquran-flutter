import 'package:material_ui/material_ui.dart';
import '../data/quran_repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ayah_action_sheet.dart';
import '../widgets/ayah_widgets.dart';

/// 604-page Medina Mushaf reader. Mirrors MushafView.tsx + MushafPage.tsx.
/// - RTL swipe: swiping right turns to the next page, swiping left to the
///   previous page (the web app's touch rule; implemented with a reversed
///   PageView).
/// - Pages mode always renders Hafs text: the Medina Mushaf is the Hafs
///   edition and its page mapping is Hafs-numbered. When the user reads
///   Warsh, a note is shown under the header.
/// - Header: Juz · Hizb + surah name. Footer: page number pill.
class MushafPage extends StatefulWidget {
  final AppState appState;
  final int initialPage;

  const MushafPage({
    super.key,
    required this.appState,
    required this.initialPage,
  });

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late final PageController _controller;
  late int _currentPage;
  final Map<int, Future<({PageRange info, List<PageVerseItem> verses})>>
      _pageFutures = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _controller = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<({PageRange info, List<PageVerseItem> verses})> _page(
      int page) {
    return _pageFutures.putIfAbsent(
        page, () => QuranRepository.getVersesForPage(page));
  }

  void _goToPage(int page) {
    final p = page.clamp(1, 604);
    _controller.jumpToPage(p - 1);
  }

  Future<void> _showJumpDialog() async {
    final s = widget.appState.settings.isArabic ? S.arabic : S.english;
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.jumpToPage),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: s.enterPageNumber),
          onSubmitted: (v) {
            final n = int.tryParse(v);
            if (n != null) Navigator.of(context).pop(n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text);
              Navigator.of(context).pop(n);
            },
            child: Text(s.go),
          ),
        ],
      ),
    );
    if (value != null) _goToPage(value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.mushaf),
        actions: [
          IconButton(
            icon: const Icon(Icons.find_in_page_outlined),
            tooltip: s.jumpToPage,
            onPressed: _showJumpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              // Reversed so swiping right turns to the next page,
              // matching the web app's RTL swipe rule.
              reverse: true,
              itemCount: 604,
              onPageChanged: (index) {
                setState(() => _currentPage = index + 1);
              },
              itemBuilder: (context, index) {
                final page = index + 1;
                return _MushafPageView(
                  appState: widget.appState,
                  pageNumber: page,
                  future: _page(page),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: s.previous,
                    onPressed: _currentPage > 1
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                  ),
                  Text(
                    settings.isArabic
                        ? 'صفحة $_currentPage / ٦٠٤'
                        : 'Page $_currentPage / 604',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: s.next,
                    onPressed: _currentPage < 604
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafPageView extends StatelessWidget {
  final AppState appState;
  final int pageNumber;
  final Future<({PageRange info, List<PageVerseItem> verses})> future;

  const _MushafPageView({
    required this.appState,
    required this.pageNumber,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    final settings = appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;

    return FutureBuilder<({PageRange info, List<PageVerseItem> verses})>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final info = snapshot.data!.info;
        final verses = snapshot.data!.verses;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header: Juz · Hizb + surah name
                FutureBuilder<SurahMeta?>(
                  future: QuranRepository.getMeta(info.startSurah),
                  builder: (context, metaSnap) {
                    final meta = metaSnap.data;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          settings.isArabic
                              ? '${s.juz} ${info.juz} · ${s.hizb} ${info.hizb}'
                              : '${s.juz} ${info.juz} · ${s.hizb} ${info.hizb}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          settings.isArabic
                              ? 'سورة ${meta?.arabicName ?? ''}'
                              : (meta?.name ?? ''),
                          style: const TextStyle(
                            fontFamily: NurTheme.arabicFont,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Divider(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.6)),
                if (settings.mushaf == Mushaf.warsh)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      s.mushafHafsNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                // Page text
                Expanded(
                  child: SingleChildScrollView(
                    child: FlowingAyahText(
                      items: verses
                          .map((v) => (ayah: v.ayah, surah: v.surah))
                          .toList(),
                      // Fixed 20px font in pages mode, like the web app.
                      fontSize: 20,
                      showTajweed: settings.showTajweed,
                      isBookmarked: (surah, ayah) =>
                          appState.isBookmarked(surah, ayah),
                      onAyahTap: (surah, ayah) async {
                        final item = verses.firstWhere((v) =>
                            v.surah == surah && v.ayah.verse == ayah);
                        await showAyahActionSheet(
                          context,
                          appState: appState,
                          surahNumber: surah,
                          ayahNumber: ayah,
                          ayahText: item.ayah.text,
                          // Pages mode always shows Hafs.
                          mushafOverride: Mushaf.hafs,
                        );
                      },
                    ),
                  ),
                ),
                // Footer: page number pill
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      settings.isArabic
                          ? 'صفحة $pageNumber'
                          : 'Page $pageNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
