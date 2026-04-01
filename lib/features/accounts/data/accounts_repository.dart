import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/account_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AccountsRepository
// ─────────────────────────────────────────────────────────────────────────────

class AccountsRepository {
  final SupabaseClient _client;

  const AccountsRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ── Bancos dominicanos ────────────────────────────────────────────────────

  static const List<Map<String, String>> dominicanBanks = [
    {'name': 'Banco Popular', 'emoji': '🏦'},
    {'name': 'Banreservas', 'emoji': '🏛️'},
    {'name': 'Scotiabank', 'emoji': '🏦'},
    {'name': 'BHD León', 'emoji': '🏦'},
    {'name': 'Banco Santa Cruz', 'emoji': '🏦'},
    {'name': 'Banco del Progreso', 'emoji': '🏦'},
    {'name': 'Citibank', 'emoji': '🏦'},
    {'name': 'Banco Caribe', 'emoji': '🏦'},
    {'name': 'Asociación Popular', 'emoji': '🏦'},
  ];

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Devuelve todas las cuentas activas del usuario, ordenadas por sort_order.
  Future<List<AccountModel>> fetchAll() async {
    final data = await _client
        .from('accounts')
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return (data as List).map((e) => AccountModel.fromJson(e)).toList();
  }

  /// Stream en tiempo real via Supabase Realtime.
  Stream<List<AccountModel>> watchAll() {
    return _client
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('sort_order', ascending: true)
        .map((rows) => rows
            .where((r) => r['is_active'] == true)
            .map(AccountModel.fromJson)
            .toList());
  }

  /// Devuelve la cuenta marcada como predeterminada, o null si no hay ninguna.
  Future<AccountModel?> getDefault() async {
    final data = await _client
        .from('accounts')
        .select()
        .eq('user_id', _userId)
        .eq('is_default', true)
        .eq('is_active', true)
        .maybeSingle();
    if (data == null) return null;
    return AccountModel.fromJson(data);
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Inserta una cuenta nueva y devuelve el registro con id generado.
  Future<AccountModel> insert(AccountModel account) async {
    final data = await _client
        .from('accounts')
        .insert({
          'user_id': _userId,
          'name': account.name,
          'type': account.type.name,
          'balance': account.balance,
          'bank_name': account.bankName,
          'color': account.color ?? _defaultColor(account.type),
          'is_default': account.isDefault,
          'is_active': true,
          'sort_order': account.sortOrder,
        })
        .select()
        .single();
    return AccountModel.fromJson(data);
  }

  static String _defaultColor(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return '#7C3AED';
      case AccountType.credit:
        return '#DC2626';
      case AccountType.cash:
        return '#059669';
      default:
        return '#3B5BDB';
    }
  }

  /// Actualiza los campos editables de una cuenta existente.
  Future<void> update(AccountModel account) async {
    await _client
        .from('accounts')
        .update({
          'name': account.name,
          'type': account.type.name,
          'balance': account.balance,
          'bank_name': account.bankName,
          'color': account.color,
          'is_default': account.isDefault,
          'sort_order': account.sortOrder,
        })
        .eq('id', account.id)
        .eq('user_id', _userId);
  }

  /// Soft-delete: marca is_active=false sin borrar el registro.
  Future<void> softDelete(String id) async {
    await _client
        .from('accounts')
        .update({'is_active': false})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Resumen financiero ────────────────────────────────────────────────────

  /// Calcula el resumen financiero directamente desde la tabla accounts.
  Future<FinancialSummary> getSummary() async {
    final data = await _client
        .from('accounts')
        .select('type, balance')
        .eq('user_id', _userId)
        .eq('is_active', true);

    double available = 0;
    double saved = 0;
    double owed = 0;

    for (final row in data as List) {
      final balance = (row['balance'] as num).toDouble();
      final type = AccountType.values.firstWhere(
        (e) => e.name == (row['type'] as String? ?? 'general'),
        orElse: () => AccountType.general,
      );
      if (type.isSpendable) available += balance;
      if (type == AccountType.savings) saved += balance;
      if (type == AccountType.credit) owed += balance;
    }

    return FinancialSummary(available: available, saved: saved, owed: owed);
  }

  // ── Transferencias ────────────────────────────────────────────────────────

  /// Inserta un registro en la tabla transfers.
  /// Los triggers de Supabase actualizan los saldos de las cuentas.
  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    await _client.from('transfers').insert({
      'user_id': _userId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'description': description,
      'date': (date ?? DateTime.now()).toIso8601String().split('T').first,
    });
  }

  /// Devuelve las últimas [limit] transferencias del usuario.
  Future<List<TransferModel>> fetchTransfers({int limit = 20}) async {
    final data = await _client
        .from('transfers')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => TransferModel.fromJson(e)).toList();
  }
}
