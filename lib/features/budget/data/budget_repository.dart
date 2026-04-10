import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/budget_model.dart';
import '../../../core/local_storage/hive_service.dart';
import '../../../core/network/sync_service.dart';

export '../domain/budget_model.dart';

class BudgetRepository {
  final SupabaseClient _client;
  final SyncService _syncService;

  BudgetRepository(this._client) : _syncService = SyncService(_client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Budget>> fetchAll({
    required int month,
    required int year,
  }) async {
    // 1. Obtener de Hive filtrando por mes/año
    var budgets = HiveService.getAllBudgets()
        .where((b) => b.userId == _userId && b.month == month && b.year == year)
        .toList();

    // 2. Si Hive está vacío para este mes, intentar copiar del mes anterior localmente
    if (budgets.isEmpty) {
      final prevDate = DateTime(year, month - 1);
      final prevBudgets = HiveService.getAllBudgets()
          .where((b) => b.userId == _userId && b.month == prevDate.month && b.year == prevDate.year)
          .toList();

      if (prevBudgets.isNotEmpty) {
        for (final pb in prevBudgets) {
          final nb = Budget(
            id: const Uuid().v4(),
            userId: _userId,
            category: pb.category,
            limitAmount: pb.limitAmount,
            spent: 0,
            month: month,
            year: year,
            alertAt80: pb.alertAt80,
            isSynced: false,
          );
          await HiveService.saveBudget(nb);
        }
        // Recargar de la caja local ya con los nuevos
        budgets = HiveService.getAllBudgets()
            .where((b) => b.userId == _userId && b.month == month && b.year == year)
            .toList();
      }
    }

    _syncService.syncAll();
    return budgets;
  }

  Future<void> add(Budget b) async {
    final existing = HiveService.getAllBudgets().firstWhere(
      (eb) => eb.category == b.category && eb.month == b.month && eb.year == b.year,
      orElse: () => b,
    );

    final toSave = Budget(
      id: existing.id.isEmpty ? const Uuid().v4() : existing.id,
      userId: _userId,
      category: b.category,
      limitAmount: b.limitAmount,
      spent: existing.spent,
      month: b.month,
      year: b.year,
      alertAt80: b.alertAt80,
      isSynced: false,
    );

    await HiveService.saveBudget(toSave);
    _syncService.syncAll();
  }

  Future<void> delete(String id) async {
    final budget = HiveService.budgetsBox.get(id);
    if (budget != null) {
      final updated = budget.copyWith(isDeleted: true, isSynced: false);
      await HiveService.saveBudget(updated);
    }
    _syncService.syncAll();
  }

  double totalSpentPercentage(List<Budget> budgets) {
    if (budgets.isEmpty) return 0;
    final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
    return totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
  }
}
