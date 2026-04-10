import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/budget_repository.dart';

export '../domain/budget_model.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(Supabase.instance.client),
);

// ── Presupuestos del mes actual ───────────────────────────────────────────────

final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  final now = DateTime.now();
  return repo.fetchAll(month: now.month, year: now.year);
});

// ── Notifier para mutaciones ─────────────────────────────────────────────────

class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repo;
  final Ref _ref;

  BudgetNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> add(Budget b) async {
    state = const AsyncLoading();
    try {
      await _repo.add(b);
      _ref.invalidate(budgetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> remove(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      _ref.invalidate(budgetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>(
  (ref) => BudgetNotifier(ref.watch(budgetRepositoryProvider), ref),
);

