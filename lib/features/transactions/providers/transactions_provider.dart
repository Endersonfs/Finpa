import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/providers/accounts_provider.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import 'transaction_provider.dart';

// ── TransactionNotifier ───────────────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repo;
  final Ref _ref;

  TransactionNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> add(Transaction t, {String? accountId}) async {
    state = const AsyncLoading();
    try {
      await _repo.add(t, accountId: accountId);
      _ref.invalidate(transactionsProvider);
      if (accountId != null) {
        _ref.invalidate(accountsStreamProvider);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> remove(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(accountsStreamProvider);
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

