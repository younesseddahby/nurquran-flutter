import 'package:material_ui/material_ui.dart';
import '../data/quran_repository.dart';
import '../models.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ayah_action_sheet.dart';
import '../widgets/ayah_widgets.dart';

/// Continuous-scroll reader for one surah. Mirrors src/pages/Surah.jsx.
/// - Arabic-only flowing text when (Warsh + Arabic UI) or (Arabic UI
///   without a search query), exactly like the web app.
/// - Otherwise per-ayah cards with the English translation (when the UI
///   is English and translations are enabled).
/// - Progress is saved for the topmost visible ayah on scroll end
///   (card mode) and on ayah tap (both modes).
/// - A target ayah (?ayah=N) scrolls to the ayah and highlights it.
///   In flowing mode the jump cannot target a span, so that visit renders
///   in card mode instead.
class SurahPage extends StatefulWidget {
  final AppState appState;
  final int surah;
  final int? targetAyah;

  const SurahPage({
    super.key,
    required this.appState,
    required this.surah,
    this.targetAyah,
  });

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  SurahData? _data;
  bool _loading = true;
  int? _highlightAyah;
  final Map<int, GlobalKey> _ayahKeys = {};

  bool get _isAr => widget.appState.settings.isArabic;
  bool get _flowing {
    final settings = widget.appState.settings;
    if (widget.targetAyah != null) return false; // jump needs card mode
    return (settings.mushaf == Mushaf.warsh && settings.language == 'arabic') ||
        (_isAr && _query.isEmpty);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await QuranRepository.getSurah(
        widget.surah, widget.appState.settings.mushaf);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
    // Jump to the target ayah after the first frame.
    if (widget.targetAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToAyah());
    }
  }

  void _jumpToAyah() {
    final target = widget.targetAyah;
    if (target == null) return;
    final key = _ayahKeys[target];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3,
      );
      setState(() => _highlightAyah = target);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightAyah = null);
      });
    }
  }

  String _stripDiacritics(String s) => s.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');

  List<int> _filteredIndices() {
    final data = _data;
    if (data == null) return [];
    final indices =
        List<int>.generate(data.arabic.length, (i) => i);
    final q = _query.trim();
    if (q.isEmpty) return indices;
    final lower = q.toLowerCase();
    return indices.where((i) {
      final a = data.arabic[i];
      if (a.verse.toString() == q) return true;
      final searchable = a.textEmlaey ?? _stripDiacritics(a.text);
      if (searchable.contains(lower)) return true;
      final tr = data.english[i];
      if (tr.text.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();
  }

  void _onScrollEnd() {
    // Save progress for the topmost visible ayah (card mode only).
    if (_flowing || _data == null) return;
    final viewport = _scrollController.position.viewportDimension;
    final center = viewport * 0.4;
    int? best;
    double bestDistance = double.infinity;
    for (final entry in _ayahKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top < 0 || top > viewport) continue;
      final distance = (top - center).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry.key;
      }
    }
    if (best != null) {
      widget.appState.saveProgress(Progress(
        surah: widget.surah,
        ayah: best,
        mushaf: widget.appState.settings.mushaf,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  Future<void> _openAyahActions(Ayah ayah, String? translation) async {
    await showAyahActionSheet(
      context,
      appState: widget.appState,
      surahNumber: widget.surah,
      ayahNumber: ayah.verse,
      ayahText: ayah.text,
      translationText: translation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;

    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.meta?.arabicName ?? s.surah),
        leading: IconButton(
          icon: Icon(
              settings.isArabic ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading || _data == null
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                _onScrollEnd();
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(
                            image: AssetImage(settings.isDark
                                ? 'assets/images/card2.webp'
                                : 'assets/images/card1.webp'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                settings.isArabic
                                    ? '${s.quran} · ${_data!.meta!.number} · ${_data!.meta!.revelation == 'Meccan' ? 'مكية' : 'مدنية'}'
                                    : 'Surah ${_data!.meta!.number} · ${_data!.meta!.revelation}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black38,
                                        blurRadius: 6)
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _data!.meta!.arabicName,
                                style: const TextStyle(
                                  fontFamily: NurTheme.arabicFont,
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black38,
                                        blurRadius: 8,
                                        offset: Offset(0, 2))
                                  ],
                                ),
                              ),
                              if (!settings.isArabic)
                                Text(
                                  _data!.meta!.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                settings.isArabic
                                    ? '${_data!.arabic.length} ${s.verses}'
                                    : '${_data!.meta!.englishName} · ${_data!.arabic.length} verses',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // In-surah search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        textAlign: settings.isArabic
                            ? TextAlign.right
                            : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: s.searchInSurah,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
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
                    ),

                    // Ayahs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _flowing
                          ? _buildFlowing()
                          : _buildCards(),
                    ),

                    // Prev / next surah
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
                      child: Row(
                        children: [
                          if (widget.surah > 1)
                            Expanded(
                                child: _NavCard(
                              label: s.previous,
                              surah: widget.surah - 1,
                              isArabicUi: settings.isArabic,
                              onTap: () {
                                Navigator.of(context).pushReplacementNamed(
                                  '/surah',
                                  arguments: {'surah': widget.surah - 1},
                                );
                              },
                            ))
                          else
                            const Expanded(child: SizedBox.shrink()),
                          const SizedBox(width: 12),
                          if (widget.surah < 114)
                            Expanded(
                                child: _NavCard(
                              label: s.next,
                              surah: widget.surah + 1,
                              isArabicUi: settings.isArabic,
                              onTap: () {
                                Navigator.of(context).pushReplacementNamed(
                                  '/surah',
                                  arguments: {'surah': widget.surah + 1},
                                );
                              },
                            ))
                          else
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFlowing() {
    final settings = widget.appState.settings;
    final items = _data!.arabic
        .map((a) => (ayah: a, surah: widget.surah))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: FlowingAyahText(
        items: items,
        fontSize: settings.arabicSize,
        showTajweed: settings.showTajweed,
        isBookmarked: (surah, ayah) =>
            widget.appState.isBookmarked(surah, ayah),
        onAyahTap: (surah, ayah) {
          final a = _data!.arabic.firstWhere((x) => x.verse == ayah);
          _openAyahActions(a, null);
        },
      ),
    );
  }

  Widget _buildCards() {
    final settings = widget.appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;
    final showTranslation =
        settings.language == 'english' && settings.showTranslation;
    final indices = _filteredIndices();
    if (indices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text(s.noMatches)),
      );
    }
    return Column(
      children: indices.map((i) {
        final a = _data!.arabic[i];
        final tr = _data!.english[i];
        final bookmarked =
            widget.appState.isBookmarked(widget.surah, a.verse);
        final key = _ayahKeys.putIfAbsent(a.verse, () => GlobalKey());
        final highlighted = _highlightAyah == a.verse;
        return Container(
          key: key,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: highlighted
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor,
              width: highlighted ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _openAyahActions(a, tr.text),
                    child: AyahNumberBadge(
                      number: a.verse,
                      isBookmarked: bookmarked,
                      size: 48,
                    ),
                  ),
                  Row(
                    children: [
                      if (a.structural == 'hizb' && a.hizb != null)
                        HizbMarkerWidget(number: a.hizb!),
                      TextButton.icon(
                        onPressed: () => openTafseer(context, widget.surah,
                            ayah: a.verse),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: Text(s.showTafseer),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _openAyahActions(a, tr.text),
                child: Text.rich(
                  TextSpan(
                    children: ayahSpans(
                      a.text,
                      baseStyle: TextStyle(
                        fontFamily: NurTheme.arabicFont,
                        fontSize: settings.arabicSize,
                        height: 2.6,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      showTajweed: settings.showTajweed,
                    ),
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
              if (showTranslation && tr.text.isNotEmpty) ...[
                const SizedBox(height: 20),
                Divider(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  tr.text,
                  style: TextStyle(
                    fontSize: settings.translationSize,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String label;
  final int surah;
  final bool isArabicUi;
  final VoidCallback onTap;

  const _NavCard({
    required this.label,
    required this.surah,
    required this.isArabicUi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SurahMeta?>(
      future: QuranRepository.getMeta(surah),
      builder: (context, snapshot) {
        final meta = snapshot.data;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                if (!isArabicUi)
                  Text(
                    meta?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text(
                  meta?.arabicName ?? '',
                  style: TextStyle(
                    fontFamily: NurTheme.arabicFont,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
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
