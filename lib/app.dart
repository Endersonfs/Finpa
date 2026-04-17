import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'core/network/sync_service.dart';

class FinPaApp extends ConsumerStatefulWidget {
  const FinPaApp({super.key});

  @override
  ConsumerState<FinPaApp> createState() => _FinPaAppState();
}

class _FinPaAppState extends ConsumerState<FinPaApp> {
  @override
  void initState() {
    super.initState();
    // Ejecutar inicializaciones después del primer frame para no bloquear el dibujo inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSync();
      _initLanguage();
    });
  }

  void _initSync() {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentSession != null) {
      // Ejecutar en segundo plano sin bloquear
      SyncService(supabase).syncAll().catchError((e) {
        // Silently catch sync errors
      });
    }
  }

  void _initLanguage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(languageNotifierProvider.notifier).loadTranslations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final router    = ref.watch(routerProvider);
    final langState = ref.watch(languageNotifierProvider);

    return MaterialApp.router(
      title: 'FinPa',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  themeMode,
      routerConfig: router,
      
      // Localization
      locale: langState.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
    );
  }
}
