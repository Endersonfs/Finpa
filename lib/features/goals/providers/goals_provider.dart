import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/goals_repository.dart';
import '../domain/goal_model.dart';

export '../domain/goal_model.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(Supabase.instance.client),
);

// StreamProvider: actualiza la lista de metas en tiempo real.
final goalsProvider = StreamProvider.autoDispose<List<SavingGoal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchAll();
});

class GoalNotifier extends StateNotifier<AsyncValue<void>> {
  final GoalRepository _repo;
  final Ref _ref;

  GoalNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> add(SavingGoal g) async {
    state = const AsyncLoading();
    try {
      await _repo.add(g);
      _ref.invalidate(goalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deposit(String id, double amount, {String? accountId}) async {
    state = const AsyncLoading();
    try {
      await _repo.addDeposit(id, amount, accountId: accountId);
      _ref.invalidate(goalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> remove(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      _ref.invalidate(goalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<void>>(
  (ref) => GoalNotifier(ref.watch(goalRepositoryProvider), ref),
);

