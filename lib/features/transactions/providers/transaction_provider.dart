import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../../../core/providers/currency_provider.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../../core/constants/currencies.dart';

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
  final txsAsync = ref.watch(transactionsProvider);
  final accountsAsync = ref.watch(accountsStreamProvider);
  final currencyState = ref.watch(currencyNotifierProvider);
  final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

  if (txsAsync is AsyncData && accountsAsync is AsyncData) {
    final txs = txsAsync.value!;
    final accounts = accountsAsync.value!;
    
    double income = 0, expense = 0;
    for (final t in txs) {
      final account = accounts.where((a) => a.id == t.accountId).firstOrNull;
      final transactionCurrency = account?.currency ?? AppCurrency.dop;
      final convertedAmount = currencyNotifier.convert(
        t.amount, 
        transactionCurrency, 
        currencyState.baseCurrency
      );

      if (t.isIncome) income += convertedAmount;
      else expense += convertedAmount;
    }
    return AsyncData({'income': income, 'expense': expense});
  }
  
  return const AsyncLoading();
});

// ── Gastos por categoría del mes actual — derivado del stream ────────────────

final categoryExpensesProvider =
    Provider.autoDispose<AsyncValue<Map<String, double>>>((ref) {
  final txsAsync = ref.watch(transactionsProvider);
  final accountsAsync = ref.watch(accountsStreamProvider);
  final currencyState = ref.watch(currencyNotifierProvider);
  final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

  if (txsAsync is AsyncData && accountsAsync is AsyncData) {
    final txs = txsAsync.value!;
    final accounts = accountsAsync.value!;
    
    final result = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      final account = accounts.where((a) => a.id == t.accountId).firstOrNull;
      final transactionCurrency = account?.currency ?? AppCurrency.dop;
      final convertedAmount = currencyNotifier.convert(
        t.amount, 
        transactionCurrency, 
        currencyState.baseCurrency
      );

      result[t.category] = (result[t.category] ?? 0) + convertedAmount;
    }
    return AsyncData(result);
  }
  
  return const AsyncLoading();
});
