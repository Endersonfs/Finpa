import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/goal_repository.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(Supabase.instance.client),
);

// ── Metas del usuario ─────────────────────────────────────────────────────────

final goalsProvider = FutureProvider.autoDispose<List<SavingGoal>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.fetchAll();
});
