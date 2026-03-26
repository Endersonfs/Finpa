import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/accounts_repository.dart';
import '../domain/account_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(Supabase.instance.client),
);

// ── Stream en tiempo real (Supabase Realtime) ─────────────────────────────────

final accountsStreamProvider = StreamProvider<List<AccountModel>>((ref) {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.watchAll();
});

// ── Cuenta predeterminada ─────────────────────────────────────────────────────

final defaultAccountProvider = FutureProvider<AccountModel?>((ref) {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.getDefault();
});

// ── Resumen financiero ────────────────────────────────────────────────────────

final financialSummaryProvider =
    FutureProvider.autoDispose<FinancialSummary>((ref) {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.getSummary();
});

// ── AccountNotifier ───────────────────────────────────────────────────────────

/// Maneja operaciones de escritura sobre cuentas: alta y baja.
class AccountNotifier extends StateNotifier<AsyncValue<void>> {
  final AccountsRepository _repo;
  final Ref _ref;

  AccountNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> addBankAccount({
    required String name,
    required String bankName,
    required double initialBalance,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.insert(AccountModel(
        id: '',
        userId: '',
        name: name,
        type: AccountType.bank,
        balance: initialBalance,
        bankName: bankName,
        isDefault: false,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));
      _ref.invalidate(financialSummaryProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addSavingsAccount({
    required String name,
    required double initialBalance,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.insert(AccountModel(
        id: '',
        userId: '',
        name: name,
        type: AccountType.savings,
        balance: initialBalance,
        isDefault: false,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));
      _ref.invalidate(financialSummaryProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.softDelete(id);
      _ref.invalidate(financialSummaryProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final accountNotifierProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<void>>(
  (ref) => AccountNotifier(
    ref.watch(accountsRepositoryProvider),
    ref,
  ),
);

// ── TransferNotifier ──────────────────────────────────────────────────────────

/// Maneja la operación "mover dinero" entre cuentas.
class TransferNotifier extends StateNotifier<AsyncValue<void>> {
  final AccountsRepository _repo;
  final Ref _ref;

  TransferNotifier(this._repo, this._ref) : super(const AsyncData(null));

  /// Retorna true si la operación fue exitosa.
  Future<bool> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.transfer(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        description: description,
        date: date,
      );
      _ref.invalidate(financialSummaryProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final transferNotifierProvider =
    StateNotifierProvider<TransferNotifier, AsyncValue<void>>(
  (ref) => TransferNotifier(
    ref.watch(accountsRepositoryProvider),
    ref,
  ),
);
