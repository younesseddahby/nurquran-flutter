import 'package:material_ui/material_ui.dart';
import '../data/quran_repository.dart';
import '../models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';

/// Tafseer Al-Muyassar. Mirrors src/pages/Tafseer.jsx:
/// a surah list, then per-surah entries (ayah text + tafseer) with a
/// link back to the reading position for each ayah.
class TafseerListPage extends StatefulWidget {
  final AppState appState;
  const TafseerListPage({super.key, required this.appState});

  @override
  State<TafseerListPage> createState() => _TafseerListPageState();
}

class _TafseerListPageState extends State<TafseerListPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = widget.appState.settings.isArabic ? S.arabic : S.english;
    final isAr = widget.appState.settings.isArabic;
    return Scaffold(
      appBar: AppBar(title: Text(s.tafseerTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              decoration: InputDecoration(
                hintText: s.tafseerSearch,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              s.tafseerSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SurahMeta>>(
              future: QuranRepository.surahs(),
              builder: (context, snapshot) {
                final all = snapshot.data;
                if (all == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final q = _q.trim().toLowerCase();
                final filtered = all.where((x) {
                  if (q.isEmpty) return true;
                  return x.name.toLowerCase().contains(q) ||
                      x.englishName.toLowerCase().contains(q) ||
                      x.arabicName.contains(q) ||
                      x.number.toString() == q;
                }).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text(s.noResults));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final meta = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => openTafseer(context, meta.number),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${meta.number}',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? meta.arabicName : meta.name,
                                      style: TextStyle(
                                        fontFamily: isAr
                                            ? NurTheme.arabicFont
                                            : null,
                                        fontSize: isAr ? 19 : 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isAr
                                          ? '${meta.revelation == 'Meccan' ? 'مكية' : 'مدنية'} · ${meta.ayahs} ${s.verses}'
                                          : '${meta.englishName} · ${meta.ayahs} verses',
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
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TafseerSurahPage extends StatefulWidget {
  final AppState appState;
  final int surah;
  final int? targetAyah;

  const TafseerSurahPage({
    super.key,
    required this.appState,
    required this.surah,
    this.targetAyah,
  });

  @override
  State<TafseerSurahPage> createState() => _TafseerSurahPageState();
}

class _TafseerSurahPageState extends State<TafseerSurahPage> {
  List<TafseerEntry>? _entries;
  SurahMeta? _meta;
  final Map<int, GlobalKey> _entryKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      QuranRepository.getTafseerForSurah(
          widget.surah, widget.appState.settings.mushaf),
      QuranRepository.getMeta(widget.surah),
    ]);
    if (!mounted) return;
    setState(() {
      _entries = results[0] as List<TafseerEntry>;
      _meta = results[1] as SurahMeta?;
    });
    if (widget.targetAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _entryKeys[widget.targetAyah];
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.2,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.isArabic
            ? 'تفسير ${_meta?.arabicName ?? ''}'
            : 'Tafseer — ${_meta?.name ?? ''}'),
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                final key =
                    _entryKeys.putIfAbsent(e.verse, () => GlobalKey());
                final highlighted = widget.targetAyah == e.verse;
                return Container(
                  key: key,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: highlighted
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5)
                          : Theme.of(context).dividerColor,
                      width: highlighted ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${s.ayah} ${e.verse}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => openReadingPosition(
                              context,
                              widget.appState,
                              surah: widget.surah,
                              ayah: e.verse,
                            ),
                            icon: const Icon(Icons.menu_book_outlined,
                                size: 18),
                            label: Text(s.goToReading),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        e.ayahText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: NurTheme.arabicFont,
                          fontSize: settings.arabicSize,
                          height: 2.2,
                        ),
                      ),
                      Divider(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.5)),
                      Text(
                        e.tafseer,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 15, height: 1.9),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
