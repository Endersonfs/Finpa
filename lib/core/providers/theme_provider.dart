import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  SharedPreferences provider
//  Sobreescrito en main.dart antes de runApp()
// ─────────────────────────────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPrefsProvider must be overridden in ProviderScope',
  ),
);

// ─────────────────────────────────────────────
//  Constantes
// ─────────────────────────────────────────────
const _kThemeKey = 'finpa_theme_mode';

// ─────────────────────────────────────────────
//  ThemeNotifier
// ─────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  late SharedPreferences _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.read(sharedPrefsProvider);
    return _fromString(_prefs.getString(_kThemeKey));
  }

  /// Claro — siempre el default si no hay valor guardado
  static ThemeMode _fromString(String? value) => switch (value) {
        'dark'   => ThemeMode.dark,
        'system' => ThemeMode.system,
        _        => ThemeMode.light, // null o 'light' → light
      };

  void _save(ThemeMode mode) {
    state = mode;
    _prefs.setString(_kThemeKey, switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
    });
  }

  void setLight()  => _save(ThemeMode.light);
  void setDark()   => _save(ThemeMode.dark);
  void setSystem() => _save(ThemeMode.system);

  /// light ↔ dark (ignora system)
  void toggle() =>
      _save(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

// ─────────────────────────────────────────────
//  Provider público
// ─────────────────────────────────────────────
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
