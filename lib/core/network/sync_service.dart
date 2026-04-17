import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local_storage/hive_service.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/accounts/domain/account_model.dart';
import '../../features/budget/domain/budget_model.dart';
import '../../features/goals/domain/goal_model.dart';

class SyncService {
  final SupabaseClient _client;
  bool _isSyncing = false;

  SyncService(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<void> syncAll() async {
    if (_userId.isEmpty) return;
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      // 1. Subir cambios locales
      await _uploadPendingTransactions();
      await _uploadPendingAccounts();
      await _uploadPendingBudgets();
      await _uploadPendingGoals();

      // 2. Descargar cambios remotos
      await _downloadNewTransactions();
      await _downloadNewAccounts();
      await _downloadNewBudgets();
      await _downloadNewGoals();

      await HiveService.updateLastSync(_userId);
    } catch (e) {
      // Evitar que errores de red detengan el flujo principal
    } finally {
      _isSyncing = false;
    }
  }

  // --- Transactions ---
  Future<void> _uploadPendingTransactions() async {
    final pending = HiveService.getPendingTransactions();
    for (final t in pending) {
      try {
        if (t.isDeleted) {
          await _client.from('transactions').delete().eq('id', t.id);
          await t.delete();
        } else {
          await _client.from('transactions').upsert(t.toJson());
          await HiveService.saveTransaction(t.copyWith(isSynced: true));
        }
      } catch (_) {}
    }
  }

  Future<void> _downloadNewTransactions() async {
    final lastSync = HiveService.getLastSync(_userId);
    var query = _client.from('transactions').select().eq('user_id', _userId);
    if (lastSync != null) query = query.gt('created_at', lastSync.toIso8601String());
    
    final data = await query;
    for (final row in data as List) {
      final t = TransactionModel.fromJson(row).copyWith(isSynced: true);
      await HiveService.saveTransaction(t);
    }
  }

  // --- Accounts ---
  Future<void> _uploadPendingAccounts() async {
    final pending = HiveService.getPendingAccounts();
    for (final a in pending) {
      try {
        if (a.isDeleted) {
          await _client.from('accounts').delete().eq('id', a.id);
          await a.delete();
        } else {
          await _client.from('accounts').upsert(a.toJson());
          await HiveService.saveAccount(a.copyWith(isSynced: true));
        }
      } catch (_) {}
    }
  }

  Future<void> _downloadNewAccounts() async {
    final lastSync = HiveService.getLastSync(_userId);
    var query = _client.from('accounts').select().eq('user_id', _userId);
    if (lastSync != null) query = query.gt('created_at', lastSync.toIso8601String());

    final data = await query;
    for (final row in data as List) {
      final a = AccountModel.fromJson(row).copyWith(isSynced: true);
      await HiveService.saveAccount(a);
    }
  }

  // --- Budgets ---
  Future<void> _uploadPendingBudgets() async {
    final pending = HiveService.getPendingBudgets();
    for (final b in pending) {
      try {
        if (b.isDeleted) {
          await _client.from('budgets').delete().eq('id', b.id);
          await b.delete();
        } else {
          await _client.from('budgets').upsert(b.toJson());
          await HiveService.saveBudget(b.copyWith(isSynced: true));
        }
      } catch (_) {}
    }
  }

  Future<void> _downloadNewBudgets() async {
    final lastSync = HiveService.getLastSync(_userId);
    var query = _client.from('budgets').select().eq('user_id', _userId);
    if (lastSync != null) query = query.gt('created_at', lastSync.toIso8601String());

    final data = await query;
    for (final row in data as List) {
      final b = Budget.fromJson(row).copyWith(isSynced: true);
      await HiveService.saveBudget(b);
    }
  }

  // --- Goals ---
  Future<void> _uploadPendingGoals() async {
    final pending = HiveService.getPendingGoals();
    for (final g in pending) {
      try {
        if (g.isDeleted) {
          await _client.from('saving_goals').delete().eq('id', g.id);
          await g.delete();
        } else {
          await _client.from('saving_goals').upsert(g.toJson());
          await HiveService.saveGoal(g.copyWith(isSynced: true));
        }
      } catch (_) {}
    }
  }

  Future<void> _downloadNewGoals() async {
    final lastSync = HiveService.getLastSync(_userId);
    final localCount = HiveService.goalsBox.length;

    var query = _client.from('saving_goals').select().eq('user_id', _userId);
    
    // Si la caja local está vacía, traer TODO ignorando lastSync
    if (localCount > 0 && lastSync != null) {
      query = query.gt('created_at', lastSync.toIso8601String());
    }

    final data = await query;
    for (final row in data as List) {
      final g = SavingGoal.fromJson(row).copyWith(isSynced: true);
      await HiveService.saveGoal(g);
    }
  }
}
