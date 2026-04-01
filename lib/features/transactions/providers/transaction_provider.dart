import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(Supabase.instance.client),
);

// ── Transacciones del mes actual — Realtime ──────────────────────────────────
// StreamProvider: la UI se actualiza sola cada vez que Supabase emite un cambio.

final transactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

// ── Resumen mensual — derivado del stream ────────────────────────────────────
// Provider<AsyncValue<T>> preserva los estados loading/error/data para la UI.

final monthlySummaryProvider =
    Provider.autoDispose<AsyncValue<Map<String, double>>>((ref) {
  return ref.watch(transactionsProvider).whenData((txs) {
    double income = 0, expense = 0;
    for (final t in txs) {
      if (t.isIncome) income += t.amount;
      else expense += t.amount;
    }
    return {'income': income, 'expense': expense};
  });
});

// ── Gastos por categoría del mes actual — derivado del stream ────────────────

final categoryExpensesProvider =
    Provider.autoDispose<AsyncValue<Map<String, double>>>((ref) {
  return ref.watch(transactionsProvider).whenData((txs) {
    final result = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  });
});
