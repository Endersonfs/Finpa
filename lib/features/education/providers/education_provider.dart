import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/education_repository.dart';
import '../data/lesson_repository.dart';
import '../domain/module_model.dart';

// ── Repositorios ─────────────────────────────────────────────────────────────

final educationRepositoryProvider = Provider<EducationRepository>(
  (ref) => EducationRepository(Supabase.instance.client),
);

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(Supabase.instance.client),
);

// ── Providers de lectura ──────────────────────────────────────────────────────

final modulesProvider = FutureProvider.autoDispose<List<ModuleModel>>((ref) {
  return ref.watch(educationRepositoryProvider).fetchModules();
});

// ── EducationNotifier ─────────────────────────────────────────────────────────

class EducationNotifier extends StateNotifier<AsyncValue<void>> {
  final EducationRepository _repo;
  final Ref _ref;

  EducationNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> markLessonComplete(String lessonId) async {
    state = const AsyncLoading();
    try {
      await _repo.markComplete(lessonId);
      _ref.invalidate(modulesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final educationNotifierProvider =
    StateNotifierProvider<EducationNotifier, AsyncValue<void>>(
  (ref) => EducationNotifier(ref.watch(educationRepositoryProvider), ref),
);

