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
      extensions: [AppStatusColors.light],
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
      extensions: [AppStatusColors.dark],
    );
  }
}

/// Semantic status colors for appointment/queue badges and action buttons
/// (pending, checked-in, confirmed, completed, cancelled, etc). Centralizing
/// these here means light/dark contrast tuning happens in one place instead
/// of being hardcoded `Colors.green` / `Colors.red` literals scattered across
/// the dashboard screens.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color confirmed;

  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.confirmed,
  });

  static final light = AppStatusColors(
    success: Colors.green.shade700,
    warning: Colors.amber.shade700,
    danger: Colors.red.shade700,
    info: Colors.blue.shade700,
    confirmed: Colors.teal.shade700,
  );

  static final dark = AppStatusColors(
    success: Colors.green.shade400,
    warning: Colors.amber.shade300,
    danger: Colors.red.shade300,
    info: Colors.blue.shade300,
    confirmed: Colors.teal.shade300,
  );

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? confirmed,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      confirmed: confirmed ?? this.confirmed,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      confirmed: Color.lerp(confirmed, other.confirmed, t)!,
    );
  }
}

/// Convenience accessor: `theme.statusColors.success`
extension AppThemeStatusColorsX on ThemeData {
  AppStatusColors get statusColors => extension<AppStatusColors>() ?? AppStatusColors.light;
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