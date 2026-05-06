# Patrón Offline-First en Finpa

## La idea central

Hive es la fuente de verdad. Supabase es el servidor de sincronización. La UI **nunca espera red** para mostrar datos.

```
Usuario escribe → Hive (inmediato) → UI actualiza
                         ↓
                   SyncService (background)
                         ↓
                    Supabase (cuando hay red)
```

---

## Flujo de escritura paso a paso

```dart
// 1. Widget llama al provider
ref.read(transactionNotifierProvider.notifier).add(transaction);

// 2. Provider llama al repository
await _repo.add(t, accountId: accountId);

// 3. Repository guarda en Hive PRIMERO (isSynced: false)
final model = TransactionModel.fromTransaction(newTransaction, isSynced: false);
await HiveService.saveTransaction(model);

// 4. Actualiza saldo de cuenta localmente (sin esperar red)
final account = HiveService.accountsBox.get(accountId);
await HiveService.saveAccount(account.copyWith(
  balance: newBalance,
  isSynced: false,
));

// 5. Dispara sync en background — sin await (no bloquea)
_syncService.syncAll(); // ← fuego y olvida
```

---

## Flujo de lectura

```dart
Future<List<Transaction>> fetchAll({int? month, int? year}) async {
  // Lee de Hive — cero latencia
  final local = HiveService.getAllTransactions()
      .where((t) => t.userId == _userId)
      .map((m) => m.toTransaction())
      .toList();

  // Dispara sync en background
  _syncService.syncAll(); // sin await

  return local; // retorna inmediatamente con datos locales
}
```

---

## Soft Delete — cómo se borran los datos

Los registros **nunca se eliminan de Hive directamente**. Se marcan con flags:

```dart
Future<void> delete(String id) async {
  final model = HiveService.transactionsBox.get(id);
  if (model != null) {
    model.isDeleted = true;   // ← marcado para borrar
    model.isSynced = false;   // ← pendiente de subir a Supabase
    await model.save();
  }

  // SyncService lo verá y llamará DELETE en Supabase
  _syncService.syncAll();
}
```

`HiveService.getAllTransactions()` ya filtra los borrados:
```dart
static List<TransactionModel> getAllTransactions() =>
    transactionsBox.values.where((t) => !t.isDeleted).toList();
```

---

## SyncService — cómo funciona la sincronización

```dart
// lib/core/network/sync_service.dart

Future<void> syncAll() async {
  if (_userId.isEmpty || _isSyncing) return;
  _isSyncing = true;

  try {
    // 1. Subir registros locales pendientes
    await _uploadPendingTransactions(); // los que tienen isSynced = false
    await _uploadPendingAccounts();
    await _uploadPendingBudgets();
    await _uploadPendingGoals();

    // 2. Descargar cambios del servidor (delta desde lastSync)
    await _downloadNewTransactions();
    await _downloadNewAccounts();
    await _downloadNewBudgets();
    await _downloadNewGoals();

    // 3. Registrar timestamp de última sync
    await HiveService.updateLastSync(_userId);
  } finally {
    _isSyncing = false;
  }
}
```

### Upload (subir pendientes)
```dart
Future<void> _uploadPendingTransactions() async {
  final pending = HiveService.getPendingTransactions(); // isSynced = false

  for (final t in pending) {
    if (t.isDeleted) {
      await _client.from('transactions').delete().eq('id', t.id);
      await t.delete(); // ahora sí borra de Hive
    } else {
      await _client.from('transactions').upsert(t.toJson());
      await HiveService.saveTransaction(t.copyWith(isSynced: true));
    }
  }
}
```

### Download (descargar delta)
```dart
Future<void> _downloadNewTransactions() async {
  final lastSync = HiveService.getLastSync(_userId);

  var query = _client.from('transactions').select().eq('user_id', _userId);

  // Solo trae lo que cambió desde la última sync (delta)
  if (lastSync != null) {
    query = query.gt('created_at', lastSync.toIso8601String());
  }

  final data = await query;
  for (final row in data as List) {
    final t = TransactionModel.fromJson(row).copyWith(isSynced: true);
    await HiveService.saveTransaction(t);
  }
}
```

---

## Boxes de Hive registradas

| Box | Tipo Dart | `typeId` |
|-----|-----------|----------|
| `transactions` | `TransactionModel` | 0 |
| `sync_metadata` | `SyncMetadata` | 1 |
| (enum AccountType) | `AccountType` | 2 |
| `accounts` | `AccountModel` | 3 |
| `budgets` | `Budget` | 4 |
| `goals` | `SavingGoal` | 5 |

> Al agregar un nuevo modelo Hive: usar `typeId: 6`, luego 7, etc. Los IDs son globales y nunca se reusan.

---

## Watchers reactivos

Para que la UI se actualice cuando Hive cambia:

```dart
Stream<List<Transaction>> watchAll({int? month, int? year}) async* {
  yield await fetchAll(month: month, year: year); // estado inicial

  await for (final _ in HiveService.transactionsBox.watch()) {
    yield await fetchAll(month: month, year: year); // cada cambio en Hive
  }
}
```

Así un `StreamProvider` en Riverpod recibe los cambios automáticamente sin polling.

---

## Ventajas y compensaciones

| Ventaja | Compensación |
|---------|-------------|
| UI instantánea, sin esperar red | Datos pueden estar desactualizados brevemente |
| Funciona offline completamente | Lógica de sync más compleja |
| No hay "loading" para lecturas | Conflictos si el mismo dato cambia en 2 dispositivos |
| Resistente a mala conectividad | Hive ocupa espacio en disco |
