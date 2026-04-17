import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_chat/data/ai_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../core/providers/language_provider.dart';

// ── Resumen mensual: { 'income': x, 'expense': x } ───────────────────────────
//  Re-expuesto desde transaction_provider para que los widgets del dashboard
//  no necesiten importar directamente la capa de transacciones.
export '../../transactions/providers/transaction_provider.dart'
    show monthlySummaryProvider, categoryExpensesProvider;

// ── Últimas 5 transacciones del mes actual — derivado del stream ──────────────
//  Se actualiza automáticamente cuando transactionsProvider emite nuevos datos.
final recentTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<Transaction>>>((ref) {
  return ref.watch(transactionsProvider).whenData(
        (all) => all.take(5).toList(),
      );
});

// ── Consejo IA del día ────────────────────────────────────────────────────────
final aiTipProvider = FutureProvider.autoDispose<String>(
  (ref) {
    final langState = ref.watch(languageNotifierProvider);
    return const AiRepository().generateAutoTip(
      languageCode: langState.locale.languageCode,
    );
  },
);
