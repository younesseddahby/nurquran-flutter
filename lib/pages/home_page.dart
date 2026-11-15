import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../data/quran_repository.dart';
import '../data/search.dart';
import '../models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/surah_card.dart';

/// Home: hero search, Continue Reading card, popular surahs.
/// Mirrors src/pages/Home.jsx.
class HomePage extends StatefulWidget {
  final AppState appState;
  const HomePage({super.key, required this.appState});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  List<SearchResult> _matches = [];
  bool _isSearching = false;
  Timer? _debounce;

  static const _popular = [1, 2, 18, 36, 55, 56, 67, 112];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final term = value.trim();
      if (term.length < 2) {
        if (mounted) setState(() => _matches = []);
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      try {
        final results = await advancedSearch(
            term, widget.appState.settings.mushaf);
        if (mounted) setState(() => _matches = results);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _openContinueReading() async {
    final progress = widget.appState.progress;
    if (progress == null) return;
    // Restore the riwaya the progress was saved in, so the reader shows
    // the same verse that was being read.
    final continueMushaf = progress.mushaf ?? widget.appState.settings.mushaf;
    if (continueMushaf != widget.appState.settings.mushaf) {
      await widget.appState.setSettings(
          (s) => s.copyWith(mushaf: continueMushaf));
    }
    if (!mounted) return;
    await openReadingPosition(
      context,
      widget.appState,
      surah: progress.surah,
      ayah: progress.ayah,
      mushaf: continueMushaf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final settings = appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;
    final isDark = settings.isDark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final progress = appState.progress;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero with search
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(isDark
                        ? 'assets/images/card2.webp'
                        : 'assets/images/card1.webp'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.appName,
                        style: const TextStyle(
                          fontFamily: NurTheme.arabicFont,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.isArabic
                            ? 'القرآن الكريم — ورش وحفص'
                            : 'The Holy Quran — Warsh & Hafs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textAlign:
                            settings.isArabic ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: s.searchPlaceholder,
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.95),
                          prefixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      if (_matches.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.98),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: _matches.map((r) {
                              final isAyahLike = r.type ==
                                      SearchResultType.ayah ||
                                  r.type == SearchResultType.reference ||
                                  r.type == SearchResultType.translation;
                              return ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: isAyahLike
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('${r.number}',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('${r.jumpAyah}',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        )
                                      : Text('${r.number}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                ),
                                title: Text(
                                  settings.isArabic
                                      ? (r.arabicName ?? r.name ?? '')
                                      : (r.name ?? ''),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  r.preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  r.type.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                onTap: () async {
                                  _searchController.clear();
                                  setState(() => _matches = []);
                                  await openSearchResult(
                                      context, appState, r);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Continue Reading
                    if (progress != null)
                      FutureBuilder<SurahMeta?>(
                        future: QuranRepository.getMeta(progress.surah),
                        builder: (context, snapshot) {
                          final meta = snapshot.data;
                          if (meta == null) {
                            return const SizedBox.shrink();
                          }
                          return InkWell(
                            onTap: _openContinueReading,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.book_outlined,
                                        color: Colors.white, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.continueReading.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          settings.isArabic
                                              ? '${meta.arabicName} · ${s.ayah} ${progress.ayah}'
                                              : '${meta.name} · ${s.ayah} ${progress.ayah}',
                                          style: TextStyle(
                                            fontFamily: settings.isArabic
                                                ? NurTheme.arabicFont
                                                : null,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Popular surahs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.popular,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // The shell switches tabs via the AppState
                              // request mechanism is only for mushaf; for
                              // the index tab we use a plain tab request.
                              appState.requestIndexTab();
                            },
                            child: Text(s.viewAll),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<List<SurahMeta>>(
                      future: QuranRepository.surahs(),
                      builder: (context, snapshot) {
                        final all = snapshot.data;
                        if (all == null) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final popular = _popular
                            .map((n) => all.firstWhere((x) => x.number == n))
                            .toList();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.4,
                          ),
                          itemCount: popular.length,
                          itemBuilder: (context, i) => SurahCard(
                            surah: popular[i],
                            isArabicUi: settings.isArabic,
                            onTap: () =>
                                openSurah(context, popular[i].number),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
