import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/local_storage/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Inicializar locales
  await initializeDateFormatting('es_ES');
  await initializeDateFormatting('en_US');

  // 1. Variables de entorno
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Silently fail if .env is missing or invalid
  }

  // 2. Supabase (solo si las credenciales están configuradas)
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }

  // 3. Hive (Offline-First)
  await HiveService.init();

  // 4. SharedPreferences — antes de runApp para inyectarlo via override
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const FinPaApp(),
    ),
  );
}
