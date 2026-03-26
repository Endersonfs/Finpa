import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/transaction.dart';

class TransactionRepository {
  final SupabaseClient _client;

  const TransactionRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Trae todas las transacciones del usuario autenticado.
  /// Si se pasan [month] y [year] filtra por ese mes/año usando el campo `date`.
  Future<List<Transaction>> fetchAll({int? month, int? year}) async {
    var query = _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    // Supabase Flutter no permite encadenar .gte/.lte después de .order
    // directamente en la misma variable, pero sí podemos aplicar el filtro
    // de rango usando la versión extendida de la query.
    if (month != null && year != null) {
      final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
      final lastDay = _lastDayOfMonth(year, month);
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', _userId)
          .gte('date', firstDay)
          .lte('date', lastDay)
          .order('date', ascending: false)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Transaction.fromJson(e)).toList();
    }

    final data = await query;
    return (data as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Inserta una nueva transacción en Supabase.
  /// El campo `id` del objeto se ignora — Supabase genera un UUID.
  /// [accountId] opcional: id de la cuenta desde la que se registra el movimiento.
  Future<void> add(Transaction t, {String? accountId}) async {
    await _client.from('transactions').insert({
      'user_id': _userId,
      'amount': t.amount,
      'type': t.type == TransactionType.income ? 'income' : 'expense',
      'category': t.category,
      'description': t.description,
      'date': t.date.toIso8601String().split('T').first,
      if (accountId != null) 'account_id': accountId,
    });
  }

  /// Elimina la transacción con el [id] dado, validando que pertenezca
  /// al usuario autenticado mediante la política RLS de Supabase.
  Future<void> delete(String id) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Devuelve un mapa con las claves `'income'` y `'expense'` sumadas
  /// para el [month]/[year] indicados.
  Future<Map<String, double>> monthlySummary({
    required int month,
    required int year,
  }) async {
    final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = _lastDayOfMonth(year, month);

    final data = await _client
        .from('transactions')
        .select('type, amount')
        .eq('user_id', _userId)
        .gte('date', firstDay)
        .lte('date', lastDay);

    double income = 0;
    double expense = 0;

    for (final row in data as List) {
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  /// Devuelve los gastos agrupados por categoría para el [month]/[year] dado.
  Future<Map<String, double>> categoryExpenses({
    required int month,
    required int year,
  }) async {
    final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = _lastDayOfMonth(year, month);

    final data = await _client
        .from('transactions')
        .select('category, amount')
        .eq('user_id', _userId)
        .eq('type', 'expense')
        .gte('date', firstDay)
        .lte('date', lastDay);

    final Map<String, double> result = {};
    for (final row in data as List) {
      final cat = row['category'] as String;
      final amount = (row['amount'] as num).toDouble();
      result[cat] = (result[cat] ?? 0) + amount;
    }
    return result;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _lastDayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';
  }
}
