import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/budget_model.dart';

export '../domain/budget_model.dart';

// ── Repository ───────────────────────────────────────────────────────────────

class BudgetRepository {
  final SupabaseClient _client;

  const BudgetRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Consulta la vista `budget_spending` para obtener presupuestos con el
  /// gasto acumulado ya calculado, filtrados por usuario, mes y año.
  Future<List<Budget>> fetchAll({
    required int month,
    required int year,
  }) async {
    final data = await _client
        .from('budget_spending')
        .select()
        .eq('user_id', _userId)
        .eq('month', month)
        .eq('year', year);

    return (data as List).map((e) => Budget.fromJson(e)).toList();
  }

  /// Inserta un nuevo presupuesto. El campo [b.id] es ignorado porque
  /// Supabase genera el UUID. El campo [b.spent] tampoco se envía al INSERT
  /// ya que es calculado por la vista.
  Future<void> add(Budget b) async {
    await _client.from('budgets').insert({
      'user_id': _userId,
      'category': b.category,
      'limit_amount': b.limitAmount,
      'month': b.month,
      'year': b.year,
      'alert_at_80': b.alertAt80,
    });
  }

  /// Elimina el presupuesto con el [id] dado.
  Future<void> delete(String id) async {
    await _client
        .from('budgets')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Calcula el porcentaje global gastado sobre todos los presupuestos.
  double totalSpentPercentage(List<Budget> budgets) {
    if (budgets.isEmpty) return 0;
    final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
    return totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
  }
}
