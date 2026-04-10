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
  /// Si no existen presupuestos para el mes/año solicitado, intenta copiar
  /// los del mes anterior (si existen) para mantener la configuración.
  Future<List<Budget>> fetchAll({
    required int month,
    required int year,
  }) async {
    // 1. Intentar buscar los del mes solicitado
    final data = await _client
        .from('budget_spending')
        .select()
        .eq('user_id', _userId)
        .eq('month', month)
        .eq('year', year);

    final budgets = (data as List).map((e) => Budget.fromJson(e)).toList();

    // 2. Si no hay nada, buscar el mes anterior para ver si podemos "heredar"
    if (budgets.isEmpty) {
      final prevDate = DateTime(year, month - 1);
      final prevData = await _client
          .from('budgets') // Usamos 'budgets' base, no la vista
          .select()
          .eq('user_id', _userId)
          .eq('month', prevDate.month)
          .eq('year', prevDate.year);

      if ((prevData as List).isNotEmpty) {
        // Copiamos los del mes pasado al nuevo mes
        final newBudgets = prevData.map((e) {
          final b = Budget.fromJson(e);
          return {
            'user_id': _userId,
            'category': b.category,
            'limit_amount': b.limitAmount,
            'month': month,
            'year': year,
            'alert_at_80': b.alertAt80,
          };
        }).toList();

        await _client.from('budgets').insert(newBudgets);

        // Volvemos a consultar la vista para traerlos con el 'spent' en 0
        return fetchAll(month: month, year: year);
      }
    }

    return budgets;
  }

  /// Inserta un nuevo presupuesto. Si ya existe uno para esa categoría/mes/año,
  /// lo actualiza en lugar de duplicarlo.
  Future<void> add(Budget b) async {
    // Verificar si ya existe para evitar duplicados en la misma categoría/mes
    final existing = await _client
        .from('budgets')
        .select('id')
        .eq('user_id', _userId)
        .eq('category', b.category)
        .eq('month', b.month)
        .eq('year', b.year)
        .maybeSingle();

    if (existing != null) {
      await _client.from('budgets').update({
        'limit_amount': b.limitAmount,
        'alert_at_80': b.alertAt80,
      }).eq('id', existing['id']);
    } else {
      await _client.from('budgets').insert({
        'user_id': _userId,
        'category': b.category,
        'limit_amount': b.limitAmount,
        'month': b.month,
        'year': b.year,
        'alert_at_80': b.alertAt80,
      });
    }
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

