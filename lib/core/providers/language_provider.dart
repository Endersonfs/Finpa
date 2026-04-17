import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences_provider.dart';

part 'language_provider.g.dart';

class LanguageState {
  final Locale locale;
  final Map<String, dynamic> translations;
  final bool isLoading;

  LanguageState({
    required this.locale,
    required this.translations,
    this.isLoading = false,
  });

  LanguageState copyWith({
    Locale? locale,
    Map<String, dynamic>? translations,
    bool? isLoading,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      translations: translations ?? this.translations,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String translate(String key) {
    final keys = key.split('.');
    dynamic value = translations;
    for (var k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }
    return value.toString();
  }
}

@Riverpod(keepAlive: true)
class LanguageNotifier extends _$LanguageNotifier {
  static const _prefKey = 'app_language';

  @override
  LanguageState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final savedLang = prefs.getString(_prefKey) ?? 'es';
    
    // Inicializamos con un mapa vacío, las traducciones se cargarán en el constructor
    // o mediante un método asíncrono. En build de Riverpod debe ser síncrono.
    // Usaremos un truco: cargar las traducciones base (es) por defecto si es posible
    // o disparar la carga asíncrona.
    
    return LanguageState(
      locale: Locale(savedLang),
      translations: {},
      isLoading: true,
    );
  }

  Future<void> loadTranslations() async {
    final lang = state.locale.languageCode;
    final String response = await rootBundle.loadString('assets/translations/$lang.json');
    final data = await json.decode(response);
    state = state.copyWith(translations: data, isLoading: false);
  }

  Future<void> setLocale(String languageCode) async {
    state = state.copyWith(isLoading: true, locale: Locale(languageCode));
    
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_prefKey, languageCode);
    
    await loadTranslations();
  }
}

// Helper extension para facilitar el uso en widgets
extension Trans on WidgetRef {
  String tr(String key) {
    return watch(languageNotifierProvider).translate(key);
  }
}
