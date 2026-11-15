import 'package:material_ui/material_ui.dart';

/// Theme — the web app's emerald palette.
/// Light primary #1f6b52, dark primary #3aa37f, dark background #09090b,
/// gold #b8860b (hizb markers, bookmarked ayah numbers).
class NurTheme {
  static const primaryLight = Color(0xFF1F6B52);
  static const primaryDark = Color(0xFF3AA37F);
  static const splashGreen = Color(0xFF124538);
  static const gold = Color(0xFFB8860B);
  static const darkBackground = Color(0xFF09090B);

  static const arabicFont = 'AmiriQuran';

  static ThemeData light() {
    const primary = primaryLight;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAF7),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFAF7),
        foregroundColor: Color(0xFF1C1917),
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData dark() {
    const primary = primaryDark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: const Color(0xFF18181B),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
