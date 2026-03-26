import 'package:supabase_flutter/supabase_flutter.dart';

// ── Entity ───────────────────────────────────────────────────────────────────

class SavingGoal {
  final String id;
  final String userId;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const SavingGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.createdAt,
  });

  /// Porcentaje completado de la meta (0.0 – puede superar 1.0).
  double get progress =>
      targetAmount > 0 ? currentAmount / targetAmount : 0;

  /// Monto restante para alcanzar la meta.
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    return SavingGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num? ?? 0).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingGoal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── Repository ───────────────────────────────────────────────────────────────

class GoalRepository {
  final SupabaseClient _client;

  const GoalRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Devuelve todas las metas de ahorro del usuario autenticado,
  /// ordenadas por fecha de creación descendente.
  Future<List<SavingGoal>> fetchAll() async {
    final data = await _client
        .from('saving_goals')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => SavingGoal.fromJson(e)).toList();
  }

  /// Inserta una nueva meta. El campo [g.id] es ignorado (Supabase genera UUID).
  Future<void> add(SavingGoal g) async {
    await _client.from('saving_goals').insert({
      'user_id': _userId,
      'title': g.title,
      'emoji': g.emoji,
      'target_amount': g.targetAmount,
      'current_amount': g.currentAmount,
      if (g.deadline != null)
        'deadline': g.deadline!.toIso8601String().split('T').first,
    });
  }

  /// Actualiza únicamente el monto actual de la meta con [id].
  Future<void> updateAmount(String id, double newAmount) async {
    await _client
        .from('saving_goals')
        .update({'current_amount': newAmount})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Elimina la meta con el [id] dado.
  Future<void> delete(String id) async {
    await _client
        .from('saving_goals')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
