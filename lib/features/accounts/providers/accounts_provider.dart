import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/currency_provider.dart';
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

// ── Resumen financiero — reactivo al stream de cuentas y moneda ───────────────

final financialSummaryProvider = Provider.autoDispose<FinancialSummary?>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  final currencyState = ref.watch(currencyNotifierProvider);
  final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

  return accountsAsync.maybeWhen(
    data: (accounts) {
      double available = 0;
      double saved = 0;
      double owed = 0;

      for (final account in accounts) {
        // Convertimos el balance de la cuenta a la moneda base de la app
        final convertedBalance = currencyNotifier.convert(
          account.balance,
          account.currency,
          currencyState.baseCurrency,
        );

        if (account.type.isSpendable) {
          available += convertedBalance;
        } else if (account.type == AccountType.savings) {
          saved += convertedBalance;
        } else if (account.type == AccountType.credit) {
          owed += convertedBalance;
        }
      }

      return FinancialSummary(
        available: available,
        saved: saved,
        owed: owed,
      );
    },
    orElse: () => null,
  );
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
    String currencyCode = 'DOP',
    AccountType type = AccountType.bank,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.insert(AccountModel(
        id: '',
        userId: '',
        name: name,
        type: type,
        balance: initialBalance,
        bankName: bankName,
        isDefault: false,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
        currencyCode: currencyCode,
      ));
      _ref.invalidate(accountsStreamProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addSavingsAccount({
    required String name,
    required double initialBalance,
    String currencyCode = 'DOP',
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
        currencyCode: currencyCode,
      ));
      _ref.invalidate(accountsStreamProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.softDelete(id);
      _ref.invalidate(accountsStreamProvider);
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
      _ref.invalidate(accountsStreamProvider);
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

