import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/transaction.dart';
import '../domain/transaction_model.dart';
import '../../../core/local_storage/hive_service.dart';
import '../../../core/network/sync_service.dart';

class TransactionRepository {
  final SupabaseClient _client;
  final SyncService _syncService;

  TransactionRepository(this._client) : _syncService = SyncService(_client);

  String get _userId => _client.auth.currentUser!.id;

  /// Trae todas las transacciones — Prioridad Local (Hive)
  /// Si hay red, intenta sincronizar en segundo plano.
  Future<List<Transaction>> fetchAll({int? month, int? year}) async {
    // 1. Obtener de Hive (Instantáneo)
    final localModels = HiveService.getAllTransactions()
        .where((t) => t.userId == _userId);

    var transactions = localModels.map((m) => m.toTransaction()).toList();

    // Filtro por mes/año en memoria
    if (month != null && year != null) {
      transactions = transactions.where((t) => 
          t.date.month == month && t.date.year == year).toList();
    }

    // Ordenar (descendente por fecha y creación)
    transactions.sort((a, b) {
      final d = b.date.compareTo(a.date);
      return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
    });

    // 2. Disparar sincronización en segundo plano (No espera)
    _syncService.syncAll();

    return transactions;
  }

  Stream<List<Transaction>> watchAll({int? month, int? year}) async* {
    yield await fetchAll(month: month, year: year);
    await for (final _ in HiveService.transactionsBox.watch()) {
      yield await fetchAll(month: month, year: year);
    }
  }

  /// Inserta una nueva transacción — Local Primero
  Future<void> add(Transaction t, {String? accountId}) async {
    final uuid = const Uuid().v4();
    final newTransaction = Transaction(
      id: uuid,
      userId: _userId,
      accountId: accountId,
      amount: t.amount,
      type: t.type,
      category: t.category,
      description: t.description,
      date: t.date,
      createdAt: DateTime.now(),
    );

    // Guardar en Hive inmediatamente
    final model = TransactionModel.fromTransaction(
      newTransaction, 
      isSynced: false
    );
    await HiveService.saveTransaction(model);

    // Actualizar saldo de la cuenta localmente si aplica
    if (accountId != null) {
      final account = HiveService.accountsBox.get(accountId);
      if (account != null) {
        final double newBalance = t.type == TransactionType.income
            ? account.balance + t.amount
            : account.balance - t.amount;
        
        await HiveService.saveAccount(account.copyWith(
          balance: newBalance,
          isSynced: false,
        ));
      }
    }

    // Actualizar presupuesto si es un gasto
    if (t.type == TransactionType.expense) {
      try {
        final budget = HiveService.getAllBudgets().firstWhere(
          (b) => b.category == t.category && b.month == t.date.month && b.year == t.date.year,
        );
        await HiveService.saveBudget(budget.copyWith(
          spent: budget.spent + t.amount,
          isSynced: false,
        ));
      } catch (_) {
        // Si no hay presupuesto para esta categoría/mes, no hacemos nada
      }
    }

    // Intentar subir a Supabase sin bloquear UI
    _syncService.syncAll();
  }

  /// Elimina una transacción — Local Primero
  Future<void> delete(String id) async {
    final model = HiveService.transactionsBox.get(id);
    if (model != null) {
      model.isDeleted = true;
      model.isSynced = false;
      await model.save();

      // Revertir saldo de la cuenta localmente
      if (model.accountId != null) {
        final account = HiveService.accountsBox.get(model.accountId!);
        if (account != null) {
          final isIncome = model.type == 'income';
          final double newBalance = isIncome
              ? account.balance - model.amount
              : account.balance + model.amount;
          
          await HiveService.saveAccount(account.copyWith(
            balance: newBalance,
            isSynced: false,
          ));
        }
      }

      // Revertir presupuesto si era un gasto
      if (model.type == 'expense') {
        try {
          final date = DateTime.parse(model.date);
          final budget = HiveService.getAllBudgets().firstWhere(
            (b) => b.category == model.category && b.month == date.month && b.year == date.year,
          );
          await HiveService.saveBudget(budget.copyWith(
            spent: (budget.spent - model.amount).clamp(0, double.infinity),
            isSynced: false,
          ));
        } catch (_) {}
      }
    }

    // Intentar procesar borrado en la nube
    _syncService.syncAll();
  }

  /// Resumen mensual basado en datos locales (Siempre disponible)
  Future<Map<String, double>> monthlySummary({
    required int month,
    required int year,
  }) async {
    final transactions = await fetchAll(month: month, year: year);

    double income = 0;
    double expense = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  /// Gastos por categoría (Local)
  Future<Map<String, double>> categoryExpenses({
    required int month,
    required int year,
  }) async {
    final transactions = await fetchAll(month: month, year: year);
    final expenseTransactions = transactions.where((t) => t.isExpense);

    final Map<String, double> result = {};
    for (final t in expenseTransactions) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }
}
