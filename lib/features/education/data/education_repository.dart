import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/lesson_model.dart';
import '../domain/module_model.dart';

// Metadata estática de cada categoría — ahora con llaves de traducción
const _kModuleMeta = {
  'presupuesto': ('💰', 'education.modules_list.budget'),
  'ahorro': ('🏦', 'education.modules_list.saving'),
  'deuda': ('📉', 'education.modules_list.debt'),
  'inversion': ('📈', 'education.modules_list.investment'),
};

class EducationRepository {
  final SupabaseClient _client;

  const EducationRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Trae lecciones de Supabase y las agrupa en ModuleModel por categoría.
  /// Aplica lógica de desbloqueo: el primer módulo siempre está desbloqueado,
  /// los siguientes se desbloquean si el anterior está completado.
  Future<List<ModuleModel>> fetchModules() async {
    // 1. Lecciones ordenadas
    final lessonsData = await _client
        .from('lessons')
        .select()
        .order('order_index', ascending: true);
    final lessons = (lessonsData as List)
        .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // 2. Progreso del usuario
    final progressData = await _client
        .from('user_lesson_progress')
        .select('lesson_id, completed')
        .eq('user_id', _userId);
    final completedIds = (progressData as List)
        .where((e) => e['completed'] == true)
        .map((e) => e['lesson_id'] as String)
        .toSet();

    // 3. Agrupar por categoría respetando el orden de aparición
    final Map<String, List<LessonModel>> grouped = {};
    for (final l in lessons) {
      grouped.putIfAbsent(l.category, () => []).add(l);
    }

    // 4. Construir módulos con lógica de desbloqueo
    final categories = grouped.keys.toList();
    final modules = <ModuleModel>[];
    bool previousCompleted = true; // el primero siempre desbloqueado

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final catLessons = grouped[cat]!;
      final meta = _kModuleMeta[cat] ?? ('📖', cat);
      final completedInModule = catLessons
          .where((l) => completedIds.contains(l.id))
          .map((l) => l.id)
          .toList();

      modules.add(ModuleModel(
        id: cat,
        title: meta.$2, // Esto ahora es una llave de traducción
        category: cat,
        iconEmoji: meta.$1,
        lessons: catLessons,
        isUnlocked: i == 0 || previousCompleted,
        completedLessonIds: completedInModule,
      ));

      previousCompleted = completedInModule.length >= catLessons.length;
    }

    return modules;
  }

  Future<void> markComplete(String lessonId) async {
    await _client.from('user_lesson_progress').upsert({
      'user_id': _userId,
      'lesson_id': lessonId,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }
}
