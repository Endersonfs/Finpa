import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/account_model.dart';
import '../../../core/local_storage/hive_service.dart';
import '../../../core/network/sync_service.dart';

class AccountsRepository {
  final SupabaseClient _client;
  final SyncService _syncService;

  static const List<Map<String, String>> dominicanBanks = [
    {
      'name': 'Efectivo',
      'logo': '',
      'emoji': '💵'
    },
    {
      'name': 'Banco Popular Dominicano',
      'logo': 'assets/icons/banks/popular.png',
      'emoji': '🏦'
    },
    {
      'name': 'Banco de Reservas',
      'logo': 'assets/icons/banks/reservas.png',
      'emoji': '🏛️'
    },
    {
      'name': 'Banco BHD',
      'logo': 'assets/icons/banks/bhd.png',
      'emoji': '🏢'
    },
    {
      'name': 'Scotiabank',
      'logo': 'assets/icons/banks/scotiabank.png',
      'emoji': '🇨🇦'
    },
    {
      'name': 'Asociación Popular (APAP)',
      'logo': 'assets/icons/banks/apap.png',
      'emoji': '🏠'
    },
    {
      'name': 'Banco Santa Cruz',
      'logo': 'assets/icons/banks/santacruz.png',
      'emoji': '⛪'
    },
    {
      'name': 'Promerica',
      'logo': 'assets/icons/banks/promerica.png',
      'emoji': '🌍'
    },
    {
      'name': 'Banesco',
      'logo': 'assets/icons/banks/banesco.png',
      'emoji': '🇻🇪'
    },
    {
      'name': 'Qik Banco Digital',
      'logo': 'assets/icons/banks/qik.png',
      'emoji': '⚡'
    },
  ];

  AccountsRepository(this._client) : _syncService = SyncService(_client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<List<AccountModel>> fetchAll() async {
    final userId = _userId;
    if (userId.isEmpty) return [];

    final local = HiveService.getAllAccounts()
        .where((a) => a.userId == userId && a.isActive)
        .toList();
    
    local.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    _syncService.syncAll();
    return local;
  }

  Stream<List<AccountModel>> watchAll() async* {
    yield await fetchAll();
    await for (final _ in HiveService.accountsBox.watch()) {
      final userId = _userId;
      if (userId.isEmpty) {
        yield [];
        continue;
      }
      final local = HiveService.getAllAccounts()
          .where((a) => a.userId == userId && a.isActive)
          .toList();
      local.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      yield local;
    }
  }

  Future<AccountModel?> getDefault() async {
    final accounts = await fetchAll();
    try {
      return accounts.firstWhere((a) => a.isDefault);
    } catch (_) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  Future<AccountModel> insert(AccountModel account) async {
    final userId = _userId;
    if (userId.isEmpty) throw Exception('Usuario no autenticado');

    final id = const Uuid().v4();
    final newAccount = AccountModel(
      id: id,
      userId: userId,
      name: account.name,
      type: account.type,
      balance: account.balance,
      bankName: account.bankName,
      color: account.color ?? _defaultColor(account.type),
      isDefault: account.isDefault,
      isActive: true,
      sortOrder: account.sortOrder,
      createdAt: DateTime.now(),
      isSynced: false,
      currencyCode: account.currencyCode,
    );

    await HiveService.saveAccount(newAccount);
    _syncService.syncAll();
    return newAccount;
  }

  static String _defaultColor(AccountType type) {
    switch (type) {
      case AccountType.savings: return '#7C3AED';
      case AccountType.credit: return '#DC2626';
      case AccountType.cash: return '#059669';
      default: return '#2F7155';
    }
  }

  Future<void> update(AccountModel account) async {
    final toUpdate = account.copyWith(isSynced: false);
    await HiveService.saveAccount(toUpdate);
    _syncService.syncAll();
  }

  Future<void> softDelete(String id) async {
    final account = HiveService.accountsBox.get(id);
    if (account != null) {
      final updated = account.copyWith(isActive: false, isSynced: false);
      await HiveService.saveAccount(updated);
    }
    _syncService.syncAll();
  }

  Future<FinancialSummary> getSummary() async {
    final accounts = await fetchAll();
    double available = 0;
    double saved = 0;
    double owed = 0;

    for (final a in accounts) {
      if (a.type.isSpendable) available += a.balance;
      if (a.type == AccountType.savings) saved += a.balance;
      if (a.type == AccountType.credit) owed += a.balance;
    }
    return FinancialSummary(available: available, saved: saved, owed: owed);
  }

  // --- Transferencias (Se manejan como transacciones especiales) ---
  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final fromAccount = HiveService.accountsBox.get(fromAccountId);
    final toAccount = HiveService.accountsBox.get(toAccountId);

    if (fromAccount == null || toAccount == null) {
      throw Exception('Una de las cuentas no existe localmente.');
    }

    final newFrom = fromAccount.copyWith(
      balance: fromAccount.balance - amount,
      isSynced: false,
    );
    final newTo = toAccount.copyWith(
      balance: toAccount.balance + amount,
      isSynced: false,
    );

    await HiveService.saveAccount(newFrom);
    await HiveService.saveAccount(newTo);
    
    _syncService.syncAll();
  }
}
