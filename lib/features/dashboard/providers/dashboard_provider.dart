import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_chat/data/ai_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';

// ── Resumen mensual: { 'income': x, 'expense': x } ───────────────────────────
//  Re-expuesto desde transaction_provider para que los widgets del dashboard
//  no necesiten importar directamente la capa de transacciones.
export '../../transactions/providers/transaction_provider.dart'
    show monthlySummaryProvider, categoryExpensesProvider;

// ── Últimas 5 transacciones del mes actual ────────────────────────────────────
//  Toma todas las transacciones del mes y devuelve solo las primeras 5.
final recentTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final all = await ref.watch(transactionsProvider.future);
  return all.take(5).toList();
});

// ── Consejo IA del día ────────────────────────────────────────────────────────
final aiTipProvider = FutureProvider.autoDispose<String>(
  (ref) => const AiRepository().generateAutoTip(),
);
