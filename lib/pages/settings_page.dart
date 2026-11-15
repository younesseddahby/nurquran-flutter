import 'package:material_ui/material_ui.dart';
import 'package:in_app_review/in_app_review.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../strings.dart';

/// Settings. Mirrors src/pages/Settings.jsx (same sections and options).
/// - Language: Arabic/English. Switching to English forces Hafs +
///   scrolling, like the web app (Arabic-only features).
/// - Mushaf: Warsh/Hafs (Arabic UI only).
/// - Navigation: pages / scrolling.
/// - Theme: light / dark. Arabic size 14–64 step 2, translation size
///   10–32 step 1. Tajweed toggle. Rate the app.
class SettingsPage extends StatelessWidget {
  final AppState appState;
  const SettingsPage({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final settings = appState.settings;
        final s = settings.isArabic ? S.arabic : S.english;
        final isAr = settings.isArabic;

        return Scaffold(
          appBar: AppBar(title: Text(s.settings)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _SectionTitle(s.reading),
              _SegmentedRow<int>(
                icon: Icons.menu_book_outlined,
                title: s.navigationStyle,
                subtitle: s.navigationStyleDesc,
                value: settings.navigationStyle == NavStyle.pages ? 0 : 1,
                options: [s.pagesMode, s.scrollingMode],
                onChanged: (i) => appState.setSettings((prev) =>
                    prev.copyWith(
                        navigationStyle:
                            i == 0 ? NavStyle.pages : NavStyle.scrolling)),
              ),
              _SwitchRow(
                icon: Icons.palette_outlined,
                title: s.showTajweed,
                subtitle: s.showTajweedDesc,
                value: settings.showTajweed,
                onChanged: (v) => appState.setSettings(
                    (prev) => prev.copyWith(showTajweed: v)),
              ),
              const SizedBox(height: 20),
              _SectionTitle(s.language),
              _SegmentedRow<int>(
                icon: Icons.language_outlined,
                title: s.language,
                subtitle: isAr ? s.readingLanguageAr : s.readingLanguageEn,
                value: isAr ? 0 : 1,
                options: const ['العربية', 'English'],
                onChanged: (i) => appState.setSettings((prev) =>
                    prev.copyWith(language: i == 0 ? 'arabic' : 'english')),
              ),
              if (isAr)
                _SegmentedRow<int>(
                  icon: Icons.auto_stories_outlined,
                  title: s.mushafSetting,
                  subtitle: s.mushafDesc,
                  value: settings.mushaf == Mushaf.warsh ? 0 : 1,
                  options: [s.warsh, s.hafs],
                  onChanged: (i) => appState.setSettings((prev) =>
                      prev.copyWith(
                          mushaf: i == 0 ? Mushaf.warsh : Mushaf.hafs)),
                ),
              if (!isAr)
                _SwitchRow(
                  icon: Icons.translate_outlined,
                  title: s.showTranslation,
                  subtitle: s.showTranslationDesc,
                  value: settings.showTranslation,
                  onChanged: (v) => appState.setSettings(
                      (prev) => prev.copyWith(showTranslation: v)),
                ),
              const SizedBox(height: 20),
              _SectionTitle(s.appearance),
              _SegmentedRow<int>(
                icon: Icons.brightness_6_outlined,
                title: s.themeSetting,
                subtitle: s.themeDesc,
                value: settings.isDark ? 1 : 0,
                options: [s.lightTheme, s.darkTheme],
                onChanged: (i) => appState.setSettings((prev) =>
                    prev.copyWith(theme: i == 0 ? 'light' : 'dark')),
              ),
              const SizedBox(height: 20),
              _SectionTitle(s.typography),
              _StepperRow(
                icon: Icons.text_fields_outlined,
                title: s.arabicSize,
                subtitle: '${settings.arabicSize.toInt()}px',
                value: settings.arabicSize,
                min: 14,
                max: 64,
                step: 2,
                onChanged: (v) => appState.setSettings(
                    (prev) => prev.copyWith(arabicSize: v)),
              ),
              if (!isAr)
                _StepperRow(
                  icon: Icons.text_fields_outlined,
                  title: s.translationSize,
                  subtitle: '${settings.translationSize.toInt()}px',
                  value: settings.translationSize,
                  min: 10,
                  max: 32,
                  step: 1,
                  onChanged: (v) => appState.setSettings(
                      (prev) => prev.copyWith(translationSize: v)),
                ),
              const SizedBox(height: 20),
              _SectionTitle(s.more),
              ListTile(
                leading: const Icon(Icons.star_outline,
                    color: Color(0xFFB8860B)),
                title: Text(s.rateApp),
                subtitle: Text(s.rateAppDesc),
                onTap: () async {
                  final review = InAppReview.instance;
                  if (await review.isAvailable()) {
                    await review.requestReview();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(s.about),
                subtitle: Text('${s.version} 2.4.0 (24)\n${s.aboutText}'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _RowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          trailing,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _RowCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<String> options;
  final ValueChanged<int> onChanged;

  const _SegmentedRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _RowCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: SegmentedButton<int>(
        segments: [
          for (var i = 0; i < options.length; i++)
            ButtonSegment<int>(value: i, label: Text(options[i])),
        ],
        selected: {value as int},
        onSelectionChanged: (selected) => onChanged(selected.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _StepperRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _RowCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          Text('${value.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}
