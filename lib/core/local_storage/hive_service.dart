import 'package:hive_flutter/hive_flutter.dart';
import '../local_storage/sync_metadata.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/accounts/domain/account_model.dart';
import '../../features/budget/domain/budget_model.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String accountsBoxName = 'accounts';
  static const String budgetsBoxName = 'budgets';
  static const String metadataBoxName = 'sync_metadata';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registro de adaptadores
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SyncMetadataAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BudgetAdapter());

    // Abrir cajas
    await Hive.openBox<TransactionModel>(transactionsBoxName);
    await Hive.openBox<AccountModel>(accountsBoxName);
    await Hive.openBox<Budget>(budgetsBoxName);
    await Hive.openBox<SyncMetadata>(metadataBoxName);
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

  // --- Metadatos ---
  static Box<SyncMetadata> get metadataBox => Hive.box<SyncMetadata>(metadataBoxName);
  static DateTime? getLastSync(String userId) => metadataBox.get(userId)?.lastSync;
  static Future<void> updateLastSync(String userId) async {
    await metadataBox.put(userId, SyncMetadata(userId: userId, lastSync: DateTime.now()));
  }
}
