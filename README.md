# Nur Quran — Flutter rewrite

A full Flutter rewrite of the Nur Quran Android app (currently Capacitor + React,
Play id `com.eddahby.quran`, version 2.3.0). Same design, same features, same
content — the Quran data files are copied unchanged from the web app, so the
text, the Warsh/Hafs numbering and the page mapping are identical.

## What is ported

- **Data (unchanged):** `warsh.json` (6,214 verses), `quran.json` (Hafs, 6,236),
  `warshToHafs.json` (59 surahs where numbering differs), `tafseer.json`
  (Tafseer Al-Muyassar), `en.json` (English translation), plus the 604-page
  mapping and the 114-surah metadata converted from the `.ts` sources.
- **Readers:** 604-page Medina Mushaf mode (swipe right = next page, Hafs text
  always, header Juz/Hizb + surah, footer page number) and continuous
  scrolling mode (per-ayah cards with translation, or flowing Arabic-only
  text in Warsh + Arabic mode).
- **Tajweed colors** — same rules as the web app (Ikhfa, Idgham with Ghunnah,
  Ghunnah, Qalqalah, Madd, Iqlab; same colors; tanween-Ikhfa deliberately
  uncolored, like the original).
- **Search** — the same engine (dual Arabic normalization, surah names,
  `2:255` / `Baqarah 255` references, translation search, same scoring).
- **Indexes:** Surah / Juz / Hizb lists with Meccan-Medinan filter
  (per-mushaf Hizb/Juz tables, incl. the fixed Warsh boundaries).
- **Bookmarks + Continue Reading** (grouped by surah, stamped with the
  mushaf they were saved in), **Tafseer Al-Muyassar** with jump-to-reading,
  **Settings** (language, mushaf, navigation style, theme, font sizes,
  tajweed toggle, translation toggle), **native share sheet**, **in-app
  review**, light/dark themes (emerald `#1f6b52` / `#3aa37f`).
- **No network, no trackers, no ads** — same as the original. All content
  is bundled; the app works fully offline.

## Run it

```bash
flutter pub get
flutter run            # phone / emulator
flutter build apk --release
```

Open the folder in Android Studio to run from there. The Android shell
uses application id `com.eddahby.quran`, minSdk 24, targetSdk 36,
version `2.4.0+24` — the same targets as the Capacitor 8 migration, so
this can ship as the next Play update (same signing key, same app id).

## Known gaps / device checks

- **Bookmarks & progress do NOT migrate automatically** from the Capacitor
  app: it stored them in the WebView's localStorage, this app uses
  SharedPreferences. A one-time native migration (read the WebView
  localStorage on first launch) is still to do before shipping as an
  update — otherwise existing users start with empty bookmarks.
- **Check on a real phone:** swipe direction in Mushaf mode (right = next
  page), the Bismillah block inside flowing text, the Uthmani font
  rendering at different sizes, and the 604-page layout.
- The Moroccan SVG pattern (`moroccan.svg`) is bundled but not yet drawn
  on the cards; the web app uses it as a decorative background.
- The web app's "Rate the app" used a native plugin; here it is
  `in_app_review`.
- Version code 24 assumes the Play listing is still on 23. Confirm in
  Play Console before uploading.
