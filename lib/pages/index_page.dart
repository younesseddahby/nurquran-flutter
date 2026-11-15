import 'package:material_ui/material_ui.dart';
import '../data/quran_repository.dart';
import '../data/sections.dart';
import '../models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../widgets/surah_card.dart';

/// Surah / Juz / Hizb index with search + Meccan/Medinan filter.
/// Mirrors src/pages/Quran.jsx.
class IndexPage extends StatefulWidget {
  final AppState appState;
  const IndexPage({super.key, required this.appState});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  String _tab = 'surah'; // 'surah' | 'juz' | 'hizb'
  String _revelationFilter = 'all'; // 'all' | 'Meccan' | 'Medinan'
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;
    final isAr = settings.isArabic;

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // Tab switcher
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _TabButton(
                          label: s.surahs,
                          icon: Icons.book_outlined,
                          selected: _tab == 'surah',
                          onTap: () => setState(() {
                            _tab = 'surah';
                            _q = '';
                          }),
                        ),
                        _TabButton(
                          label: s.juzs,
                          icon: Icons.layers_outlined,
                          selected: _tab == 'juz',
                          onTap: () => setState(() {
                            _tab = 'juz';
                            _q = '';
                          }),
                        ),
                        _TabButton(
                          label: s.hizbs,
                          icon: Icons.bookmark_outline,
                          selected: _tab == 'hizb',
                          onTap: () => setState(() {
                            _tab = 'hizb';
                            _q = '';
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _q = v),
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: _tab == 'juz'
                          ? s.searchByJuz
                          : _tab == 'hizb'
                              ? s.searchByHizb
                              : s.searchBySurah,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (_tab == 'surah') ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: s.all,
                            selected: _revelationFilter == 'all',
                            onTap: () => setState(
                                () => _revelationFilter = 'all'),
                          ),
                          _FilterChip(
                            label: s.meccan,
                            selected: _revelationFilter == 'Meccan',
                            onTap: () => setState(
                                () => _revelationFilter = 'Meccan'),
                          ),
                          _FilterChip(
                            label: s.medinan,
                            selected: _revelationFilter == 'Medinan',
                            onTap: () => setState(
                                () => _revelationFilter = 'Medinan'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _tab == 'surah'
                  ? _SurahList(
                      appState: widget.appState,
                      query: _q,
                      revelationFilter: _revelationFilter,
                    )
                  : _tab == 'juz'
                      ? _JuzList(appState: widget.appState, query: _q)
                      : _HizbList(appState: widget.appState, query: _q),
            ),
          ],
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).cardColor : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurface),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  final AppState appState;
  final String query;
  final String revelationFilter;

  const _SurahList({
    required this.appState,
    required this.query,
    required this.revelationFilter,
  });

  @override
  Widget build(BuildContext context) {
    final s = appState.settings.isArabic ? S.arabic : S.english;
    return FutureBuilder<List<SurahMeta>>(
      future: QuranRepository.surahs(),
      builder: (context, snapshot) {
        final all = snapshot.data;
        if (all == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = query.trim().toLowerCase();
        final filtered = all.where((x) {
          final matchSearch = q.isEmpty ||
              x.name.toLowerCase().contains(q) ||
              x.englishName.toLowerCase().contains(q) ||
              x.arabicName.contains(q) ||
              x.number.toString() == q;
          final matchRevelation = revelationFilter == 'all' ||
              x.revelation == revelationFilter;
          return matchSearch && matchRevelation;
        }).toList();
        if (filtered.isEmpty) {
          return Center(child: Text(s.noResults));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurahCard(
              surah: filtered[i],
              isArabicUi: appState.settings.isArabic,
              onTap: () => openSurah(context, filtered[i].number),
            ),
          ),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  final AppState appState;
  final String query;

  const _JuzList({required this.appState, required this.query});

  @override
  Widget build(BuildContext context) {
    final s = appState.settings.isArabic ? S.arabic : S.english;
    final isAr = appState.settings.isArabic;
    return FutureBuilder<List<JuzInfo>>(
      future: Sections.getJuzList(appState.settings.mushaf),
      builder: (context, snapshot) {
        final all = snapshot.data;
        if (all == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = query.trim().toLowerCase();
        final filtered = all.where((j) {
          if (q.isEmpty) return true;
          return j.juzNumber.toString() == q ||
              j.surahName.toLowerCase().contains(q) ||
              j.surahArabicName.contains(q) ||
              (isAr
                  ? 'جزء ${j.juzNumber}'.contains(q)
                  : 'juz ${j.juzNumber}'.contains(q));
        }).toList();
        if (filtered.isEmpty) {
          return Center(child: Text(s.noResults));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final j = filtered[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IndexRow(
                badgeLabel: s.juz,
                badgeNumber: j.juzNumber,
                title:
                    isAr ? j.surahArabicName : j.surahName,
                subtitle: s.juzStart(
                    j.ayahNumber, j.startHizb, j.endHizb),
                onTap: () => openReadingPosition(
                  context,
                  appState,
                  surah: j.surahNumber,
                  ayah: j.ayahNumber,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HizbList extends StatelessWidget {
  final AppState appState;
  final String query;

  const _HizbList({required this.appState, required this.query});

  @override
  Widget build(BuildContext context) {
    final s = appState.settings.isArabic ? S.arabic : S.english;
    final isAr = appState.settings.isArabic;
    return FutureBuilder<List<HizbInfo>>(
      future: Sections.getHizbList(appState.settings.mushaf),
      builder: (context, snapshot) {
        final all = snapshot.data;
        if (all == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = query.trim().toLowerCase();
        final filtered = all.where((h) {
          if (q.isEmpty) return true;
          return h.hizbNumber.toString() == q ||
              h.surahName.toLowerCase().contains(q) ||
              h.surahArabicName.contains(q) ||
              (isAr
                  ? 'حزب ${h.hizbNumber}'.contains(q)
                  : 'hizb ${h.hizbNumber}'.contains(q));
        }).toList();
        if (filtered.isEmpty) {
          return Center(child: Text(s.noResults));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final h = filtered[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IndexRow(
                badgeLabel: s.hizb,
                badgeNumber: h.hizbNumber,
                title: isAr ? h.surahArabicName : h.surahName,
                subtitle: s.hizbStart(h.ayahNumber, h.juzNumber),
                gold: true,
                onTap: () => openReadingPosition(
                  context,
                  appState,
                  surah: h.surahNumber,
                  ayah: h.ayahNumber,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _IndexRow extends StatelessWidget {
  final String badgeLabel;
  final int badgeNumber;
  final String title;
  final String subtitle;
  final bool gold;
  final VoidCallback onTap;

  const _IndexRow({
    required this.badgeLabel,
    required this.badgeNumber,
    required this.title,
    required this.subtitle,
    this.gold = false,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: gold
                    ? const Color(0xFFB8860B).withValues(alpha: 0.15)
                    : scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: gold
                          ? const Color(0xFFB8860B)
                          : scheme.primary,
                    ),
                  ),
                  Text(
                    '$badgeNumber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: gold
                          ? const Color(0xFFB8860B)
                          : scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
