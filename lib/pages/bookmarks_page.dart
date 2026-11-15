import 'package:material_ui/material_ui.dart';
import '../data/quran_repository.dart';
import '../models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';

/// Bookmarks, grouped by surah (latest first), expandable groups.
/// Mirrors src/pages/Bookmarks.jsx. Tapping a bookmark opens it in the
/// current navigation mode, in the mushaf it was saved in.
class BookmarksPage extends StatefulWidget {
  final AppState appState;
  const BookmarksPage({super.key, required this.appState});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  int? _openSurah;

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final s = appState.settings.isArabic ? S.arabic : S.english;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final bookmarks = appState.bookmarks;
        // Group by surah, items sorted by ayah, groups by latest first.
        final groups = <int, List<Bookmark>>{};
        for (final b in bookmarks) {
          groups.putIfAbsent(b.surah, () => []).add(b);
        }
        final groupList = groups.entries.map((e) {
          final items = [...e.value]..sort((a, b) => a.ayah.compareTo(b.ayah));
          final latest = items
              .map((b) => b.createdAt ?? 0)
              .fold<int>(0, (a, b) => a > b ? a : b);
          return (surah: e.key, items: items, latest: latest);
        }).toList()
          ..sort((a, b) => b.latest.compareTo(a.latest));

        return Scaffold(
          appBar: AppBar(title: Text(s.bookmarks)),
          body: bookmarks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          size: 56,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.noBookmarks,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => appState.requestIndexTab(),
                          child: Text(s.browseQuran),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: groupList.length,
                  itemBuilder: (context, i) {
                    final group = groupList[i];
                    final isOpen = _openSurah == group.surah;
                    return FutureBuilder<SurahMeta?>(
                      future: QuranRepository.getMeta(group.surah),
                      builder: (context, snapshot) {
                        final meta = snapshot.data;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _openSurah =
                                    isOpen ? null : group.surah),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${group.surah}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appState.settings.isArabic
                                                  ? (meta?.arabicName ?? '')
                                                  : (meta?.name ?? ''),
                                              style: TextStyle(
                                                fontFamily: appState
                                                        .settings.isArabic
                                                    ? NurTheme.arabicFont
                                                    : null,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${group.items.length} ${s.ayah}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(isOpen
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                    ],
                                  ),
                                ),
                              ),
                              if (isOpen)
                                ...group.items.map((b) => ListTile(
                                      leading: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: NurTheme.gold.withValues(
                                              alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${b.ayah}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: NurTheme.gold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        b.preview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontFamily: NurTheme.arabicFont,
                                          fontSize: 16,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                            Icons.bookmark_remove_outlined),
                                        onPressed: () async {
                                          await appState.toggleBookmark(b);
                                        },
                                      ),
                                      onTap: () => openReadingPosition(
                                        context,
                                        appState,
                                        surah: b.surah,
                                        ayah: b.ayah,
                                        mushaf: b.mushaf,
                                      ),
                                    )),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
