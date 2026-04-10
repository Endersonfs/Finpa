import 'package:supabase_flutter/supabase_flutter.dart';

// ── Entities ─────────────────────────────────────────────────────────────────

class Lesson {
  final String id;
  final String title;
  final String content;
  final String category;
  final int orderIndex;

  const Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.orderIndex,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LessonProgress {
  final String lessonId;
  final bool completed;
  final DateTime? completedAt;

  const LessonProgress({
    required this.lessonId,
    required this.completed,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lesson_id'] as String,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonProgress &&
          runtimeType == other.runtimeType &&
          lessonId == other.lessonId;

  @override
  int get hashCode => lessonId.hashCode;
}

// ── Repository ───────────────────────────────────────────────────────────────

class LessonRepository {
  final SupabaseClient _client;

  const LessonRepository(this._client);

  /// Devuelve todas las lecciones ordenadas por `order_index` ascendente.
  /// La tabla `lessons` contiene contenido público, no requiere user_id.
  Future<List<Lesson>> fetchLessons() async {
    final data = await _client
        .from('lessons')
        .select()
        .order('order_index', ascending: true);

    return (data as List).map((e) => Lesson.fromJson(e)).toList();
  }

  /// Devuelve el progreso de las lecciones para el [userId] indicado.
  Future<List<LessonProgress>> fetchProgress(String userId) async {
    final data = await _client
        .from('user_lesson_progress')
        .select('lesson_id, completed, completed_at')
        .eq('user_id', userId);

    return (data as List).map((e) => LessonProgress.fromJson(e)).toList();
  }

  /// Marca la lección [lessonId] como completada para el [userId] dado.
  /// Usa `upsert` para crear o actualizar el registro de progreso.
  Future<void> markCompleted(String lessonId, String userId) async {
    await _client.from('user_lesson_progress').upsert({
      'user_id': userId,
      'lesson_id': lessonId,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }
}

