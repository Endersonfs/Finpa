# Hive — Almacenamiento Local

Hive es la base de datos local de Finpa. Es la fuente de verdad — los datos se leen siempre de aquí, nunca directamente de Supabase.

---

## Cómo funciona Hive

Hive es una base de datos NoSQL orientada a objetos. Los datos se guardan en **Boxes** (como tablas), identificados por una clave (generalmente el `id` del objeto).

```
Box<TransactionModel>  ← caja con todos los TransactionModel
  key: "uuid-123"  → TransactionModel { id: "uuid-123", amount: 150, ... }
  key: "uuid-456"  → TransactionModel { id: "uuid-456", amount: 300, ... }
```

---

## HiveObject + @HiveType

Para que una clase Dart se pueda guardar en Hive:

```dart
// 1. Anotar con @HiveType (typeId único y global)
@HiveType(typeId: 0)
class TransactionModel extends HiveObject {

  // 2. Anotar cada campo con @HiveField (índice único dentro del tipo)
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final double amount;
  @HiveField(8) bool isSynced;   // ← mutable (sin final)
  @HiveField(9) bool isDeleted;  // ← mutable (sin final)

  // HiveObject da acceso a .save() y .delete()
}
```

Después de agregar o modificar un `@HiveType`, correr:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Esto genera el archivo `.g.dart` con el `TypeAdapter`.

---

## TypeIds — registro global

Los `typeId` son globales en toda la app. Nunca reusar un ID aunque el tipo haya sido eliminado.

| typeId | Clase |
|--------|-------|
| 0 | `TransactionModel` |
| 1 | `SyncMetadata` |
| 2 | `AccountType` (enum) |
| 3 | `AccountModel` |
| 4 | `Budget` |
| 5 | `SavingGoal` |
| **6** | **← próximo disponible** |

Los adapters se registran en `HiveService._registerAdapters()`:
```dart
static void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(MiNuevoModeloAdapter());
  // ...
}
```

---

## HiveService — API de acceso

Todas las operaciones de Hive pasan por `HiveService` (en `lib/core/local_storage/hive_service.dart`):

```dart
// Transacciones
HiveService.getAllTransactions()        // todas (excluye isDeleted)
HiveService.getPendingTransactions()   // las que isSynced = false
HiveService.saveTransaction(model)     // insert o update (upsert por id)

// Cuentas
HiveService.getAllAccounts()
HiveService.getPendingAccounts()
HiveService.saveAccount(model)

// Acceso directo a la caja (para watchers)
HiveService.transactionsBox.watch()    // Stream que emite en cada cambio
HiveService.transactionsBox.get(id)    // get por id
```

---

## Operaciones CRUD

```dart
// Guardar (insert o update)
await HiveService.saveTransaction(model);
// internamente: await box.put(model.id, model)

// Leer por id
final model = HiveService.transactionsBox.get(id);

// Leer todos
final all = HiveService.getAllTransactions(); // ya filtra isDeleted = false

// Borrar — soft delete (marcar, no eliminar)
model.isDeleted = true;
model.isSynced = false;
await model.save(); // HiveObject.save() actualiza en Hive automáticamente

// Borrar físico (lo hace SyncService después de confirmar en Supabase)
await model.delete(); // HiveObject.delete()
```

---

## Watchers reactivos

```dart
// Escuchar cambios en la caja de transacciones
HiveService.transactionsBox.watch()
// emite un BoxEvent cada vez que se guarda, actualiza o borra un valor

// Uso en repositorio para crear un Stream
Stream<List<Transaction>> watchAll() async* {
  yield await fetchAll();  // estado inicial

  await for (final _ in HiveService.transactionsBox.watch()) {
    yield await fetchAll();  // re-emite en cada cambio
  }
}
```

---

## Corrupción de datos — auto-recovery

`HiveService._openBoxSafe()` maneja el caso de corrupción:

```dart
static Future<void> _openBoxSafe<T>(String boxName) async {
  try {
    await Hive.openBox<T>(boxName);
  } catch (e) {
    // Si la caja está corrupta, borrar y recrear vacía
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<T>(boxName);
    // Los datos se recuperarán en la próxima sincronización con Supabase
  }
}
```

---

## Agregar un nuevo HiveType

1. Crear la clase con `@HiveType(typeId: N)` donde N es el siguiente disponible
2. Anotar campos con `@HiveField(índice)` — índices son por tipo, empiezan en 0
3. Correr `dart run build_runner build --delete-conflicting-outputs`
4. Registrar el adapter en `HiveService._registerAdapters()`
5. Abrir la caja en `HiveService.init()` con `_openBoxSafe<MiTipo>('nombre_caja')`
6. Agregar getters de acceso en `HiveService` siguiendo el patrón existente
