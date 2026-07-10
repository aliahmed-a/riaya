import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  // Branding Clinical Palette
  static const Color _primaryTeal = Color(0xFF007A87);
  static const Color _secondaryMint = Color(0xFF46B5A7);

  /// Bright Medical Light Mode Template
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryTeal,
        brightness: Brightness.light,
        primary: _primaryTeal,
        secondary: _secondaryMint,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Dark Shift Surgical Mode Template
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryTeal,
        brightness: Brightness.dark,
        primary: _primaryTeal,
        secondary: _secondaryMint,
        surface: const Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// 🟢 PERSISTENT THEME NOTIFIER: Automatically loads & auto-saves choice to SharedPreferences
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'riaya_theme_preference';

  @override
  ThemeMode build() {
    // Asynchronously pull preference from disk upon provider mount
    _loadPersistedTheme();
    return ThemeMode.system; // Fallback default until SharedPreferences loads
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_themeKey);
      if (index != null && index >= 0 && index < ThemeMode.values.length) {
        state = ThemeMode.values[index];
      }
    } catch (e) {
      debugPrint("Theme Storage Error: Unable to read preference state: $e");
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      debugPrint("Theme Storage Error: Unable to persist theme choice: $e");
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});