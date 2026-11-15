import 'package:material_ui/material_ui.dart';
import 'pages/bookmarks_page.dart';
import 'pages/home_page.dart';
import 'pages/index_page.dart';
import 'pages/mushaf_page.dart';
import 'pages/settings_page.dart';
import 'pages/surah_page.dart';
import 'pages/tafseer_page.dart';
import 'state/app_state.dart';
import 'strings.dart';
import 'theme.dart';

void main() {
  runApp(const NurQuranApp());
}

class NurQuranApp extends StatefulWidget {
  const NurQuranApp({super.key});

  @override
  State<NurQuranApp> createState() => _NurQuranAppState();
}

class _NurQuranAppState extends State<NurQuranApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        if (!_appState.loaded) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: NurTheme.splashGreen,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', width: 120),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
          );
        }
        final settings = _appState.settings;
        return MaterialApp(
          title: 'Nur Quran',
          debugShowCheckedModeBanner: false,
          theme: NurTheme.light(),
          darkTheme: NurTheme.dark(),
          themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
          // The whole chrome follows the UI language direction,
          // like the web app's <html dir> — applied in the builder so
          // pushed routes get it too.
          builder: (context, child) => Directionality(
            textDirection:
                settings.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: Shell(appState: _appState),
          onGenerateRoute: (routeSettings) {
            final name = routeSettings.name ?? '';
            if (name == '/surah') {
              final args =
                  routeSettings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => SurahPage(
                  appState: _appState,
                  surah: args['surah'] as int? ?? 1,
                  targetAyah: args['ayah'] as int?,
                ),
              );
            }
            if (name == '/tafseer') {
              return MaterialPageRoute(
                builder: (_) => TafseerListPage(appState: _appState),
              );
            }
            if (name.startsWith('/tafseer/')) {
              final surah = int.tryParse(name.split('/').last) ?? 1;
              final ayah = routeSettings.arguments as int?;
              return MaterialPageRoute(
                builder: (_) => TafseerSurahPage(
                  appState: _appState,
                  surah: surah,
                  targetAyah: ayah,
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

/// Bottom-navigation shell: Home, Quran index, Mushaf, Bookmarks,
/// Settings. Mirrors the web app's Layout navigation.
class Shell extends StatefulWidget {
  final AppState appState;
  const Shell({super.key, required this.appState});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  int _mushafPage = 1;
  int _mushafNonce = 0;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_consumeRequests);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_consumeRequests);
    super.dispose();
  }

  void _consumeRequests() {
    final request = widget.appState.mushafPageRequest;
    if (request != null) {
      widget.appState.clearMushafPageRequest();
      setState(() {
        _tab = 2;
        _mushafPage = request.clamp(1, 604);
        _mushafNonce++;
      });
      return;
    }
    if (widget.appState.indexTabRequest) {
      widget.appState.clearIndexTabRequest();
      setState(() => _tab = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.appState.settings;
    final s = settings.isArabic ? S.arabic : S.english;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomePage(appState: widget.appState),
          Scaffold(
            appBar: AppBar(title: Text(s.quran)),
            body: IndexPage(appState: widget.appState),
          ),
          MushafPage(
            key: ValueKey('mushaf-$_mushafPage-$_mushafNonce'),
            appState: widget.appState,
            initialPage: _mushafPage,
          ),
          BookmarksPage(appState: widget.appState),
          SettingsPage(appState: widget.appState),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: s.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.book_outlined),
              activeIcon: const Icon(Icons.book),
              label: s.quran),
          BottomNavigationBarItem(
              icon: const Icon(Icons.auto_stories_outlined),
              activeIcon: const Icon(Icons.auto_stories),
              label: s.mushaf),
          BottomNavigationBarItem(
              icon: const Icon(Icons.bookmark_outline),
              activeIcon: const Icon(Icons.bookmark),
              label: s.bookmarks),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: s.settings),
        ],
      ),
    );
  }
}
