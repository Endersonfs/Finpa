import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/goal_model.dart';
export '../domain/goal_model.dart';

class GoalRepository {
  final SupabaseClient _client;

  const GoalRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<SavingGoal>> fetchAll() async {
    final data = await _client
        .from('saving_goals')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => SavingGoal.fromJson(e)).toList();
  }

  /// Stream Realtime de metas — se actualiza solo al depositar, crear o borrar.
  Stream<List<SavingGoal>> watchAll() {
    return _client
        .from('saving_goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((e) => SavingGoal.fromJson(e)).toList());
  }

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

  /// Agrega [amount] al current_amount actual de la meta (fetch + update).
  Future<void> addDeposit(String id, double amount) async {
    final data = await _client
        .from('saving_goals')
        .select('current_amount')
        .eq('id', id)
        .eq('user_id', _userId)
        .single();
    final current = (data['current_amount'] as num).toDouble();
    await _client
        .from('saving_goals')
        .update({'current_amount': current + amount})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('saving_goals')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
