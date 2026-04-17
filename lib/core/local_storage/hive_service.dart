import 'package:hive_flutter/hive_flutter.dart';
import '../local_storage/sync_metadata.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/accounts/domain/account_model.dart';
import '../../features/budget/domain/budget_model.dart';
import '../../features/goals/domain/goal_model.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String accountsBoxName = 'accounts';
  static const String budgetsBoxName = 'budgets';
  static const String goalsBoxName = 'goals';
  static const String metadataBoxName = 'sync_metadata';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Registro de adaptadores
      _registerAdapters();

      // Abrir cajas con reintento si fallan (por corrupción de datos)
      await _openBoxSafe<TransactionModel>(transactionsBoxName);
      await _openBoxSafe<AccountModel>(accountsBoxName);
      await _openBoxSafe<Budget>(budgetsBoxName);
      await _openBoxSafe<SavingGoal>(goalsBoxName);
      await _openBoxSafe<SyncMetadata>(metadataBoxName);
    } catch (e) {
      // Critical error during initialization
    }
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SyncMetadataAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SavingGoalAdapter());
  }

  static Future<void> _openBoxSafe<T>(String boxName) async {
    try {
      await Hive.openBox<T>(boxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<T>(boxName);
    }
  }

  // --- Transacciones ---
  static Box<TransactionModel> get transactionsBox => Hive.box<TransactionModel>(transactionsBoxName);
  static List<TransactionModel> getAllTransactions() => transactionsBox.values.where((t) => !t.isDeleted).toList();
  static List<TransactionModel> getPendingTransactions() => transactionsBox.values.where((t) => !t.isSynced).toList();
  static Future<void> saveTransaction(TransactionModel t) async => await transactionsBox.put(t.id, t);

  // --- Cuentas ---
  static Box<AccountModel> get accountsBox => Hive.box<AccountModel>(accountsBoxName);
  static List<AccountModel> getAllAccounts() => accountsBox.values.where((a) => !a.isDeleted).toList();
  static List<AccountModel> getPendingAccounts() => accountsBox.values.where((a) => !a.isSynced).toList();
  static Future<void> saveAccount(AccountModel a) async => await accountsBox.put(a.id, a);

  // --- Presupuestos ---
  static Box<Budget> get budgetsBox => Hive.box<Budget>(budgetsBoxName);
  static List<Budget> getAllBudgets() => budgetsBox.values.where((b) => !b.isDeleted).toList();
  static List<Budget> getPendingBudgets() => budgetsBox.values.where((b) => !b.isSynced).toList();
  static Future<void> saveBudget(Budget b) async => await budgetsBox.put(b.id, b);

  // --- Metas ---
  static Box<SavingGoal> get goalsBox => Hive.box<SavingGoal>(goalsBoxName);
  static List<SavingGoal> getAllGoals() => goalsBox.values.where((g) => !g.isDeleted).toList();
  static List<SavingGoal> getPendingGoals() => goalsBox.values.where((g) => !g.isSynced).toList();
  static Future<void> saveGoal(SavingGoal g) async => await goalsBox.put(g.id, g);

  // --- Metadatos ---
  static Box<SyncMetadata> get metadataBox => Hive.box<SyncMetadata>(metadataBoxName);
  static DateTime? getLastSync(String userId) => metadataBox.get(userId)?.lastSync;
  static Future<void> updateLastSync(String userId) async {
    await metadataBox.put(userId, SyncMetadata(userId: userId, lastSync: DateTime.now()));
  }
}
