import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import 'transaction_provider.dart';

// ── TransactionNotifier ───────────────────────────────────────────────────────

/// Maneja operaciones de escritura (add / remove) con feedback de estado.
/// Tras cada operación exitosa invalida los providers de lectura para forzar
/// que la UI obtenga datos frescos de Supabase.
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repo;
  final Ref _ref;

  TransactionNotifier(this._repo, this._ref) : super(const AsyncData(null));

  /// Agrega una nueva transacción y refresca los providers relacionados.
  Future<void> add(Transaction t, {String? accountId}) async {
    state = const AsyncLoading();
    try {
      await _repo.add(t, accountId: accountId);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(monthlySummaryProvider);
      _ref.invalidate(categoryExpensesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Elimina una transacción por [id] y refresca los providers relacionados.
  Future<void> remove(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(monthlySummaryProvider);
      _ref.invalidate(categoryExpensesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>(
  (ref) => TransactionNotifier(
    ref.watch(transactionRepositoryProvider),
    ref,
  ),
);
