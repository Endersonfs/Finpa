import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    // Intentar sincronización inicial al arrancar
    _initSync();
  }

  void _initSync() {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentSession != null) {
      SyncService(supabase).syncAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final router    = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FinPa',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  themeMode,
      routerConfig: router,
    );
  }
}
