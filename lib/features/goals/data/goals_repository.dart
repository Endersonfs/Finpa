import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/goal_model.dart';
import '../../../core/local_storage/hive_service.dart';
import '../../../core/network/sync_service.dart';

export '../domain/goal_model.dart';

class GoalRepository {
  final SupabaseClient _client;
  final SyncService _syncService;

  GoalRepository(this._client) : _syncService = SyncService(_client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<SavingGoal>> fetchAll() async {
    final local = HiveService.getAllGoals()
        .where((g) => g.userId == _userId)
        .toList();
    
    local.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _syncService.syncAll();
    return local;
  }

  Stream<List<SavingGoal>> watchAll() async* {
    yield await fetchAll();
    await for (final _ in HiveService.goalsBox.watch()) {
      final local = HiveService.getAllGoals()
          .where((g) => g.userId == _userId)
          .toList();
      local.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield local;
    }
  }

  Future<void> add(SavingGoal g) async {
    final id = const Uuid().v4();
    final newGoal = SavingGoal(
      id: id,
      userId: _userId,
      title: g.title,
      emoji: g.emoji,
      targetAmount: g.targetAmount,
      currentAmount: g.currentAmount,
      deadline: g.deadline,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await HiveService.saveGoal(newGoal);
    _syncService.syncAll();
  }

  Future<void> addDeposit(String id, double amount, {String? accountId}) async {
    final goal = HiveService.goalsBox.get(id);
    if (goal != null) {
      final updated = goal.copyWith(
        currentAmount: goal.currentAmount + amount,
        isSynced: false,
      );
      await HiveService.saveGoal(updated);

      // Si se proporcionó una cuenta, descontar el saldo localmente
      if (accountId != null) {
        final account = HiveService.accountsBox.get(accountId);
        if (account != null) {
          await HiveService.saveAccount(account.copyWith(
            balance: account.balance - amount,
            isSynced: false,
          ));
        }
      }
    }
    _syncService.syncAll();
  }

  Future<void> delete(String id) async {
    final goal = HiveService.goalsBox.get(id);
    if (goal != null) {
      final updated = goal.copyWith(isDeleted: true, isSynced: false);
      await HiveService.saveGoal(updated);
    }
    _syncService.syncAll();
  }
}
