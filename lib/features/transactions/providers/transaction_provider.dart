import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(Supabase.instance.client),
);

// ── Transacciones del mes actual ─────────────────────────────────────────────

final transactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  return repo.fetchAll(month: now.month, year: now.year);
});

// ── Resumen mensual: { 'income': x, 'expense': x } ──────────────────────────

final monthlySummaryProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  return repo.monthlySummary(month: now.month, year: now.year);
});

// ── Gastos por categoría del mes actual ──────────────────────────────────────

final categoryExpensesProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  return repo.categoryExpenses(month: now.month, year: now.year);
});
