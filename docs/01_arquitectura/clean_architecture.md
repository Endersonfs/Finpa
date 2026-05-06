# Clean Architecture en Finpa

## La regla fundamental

Las dependencias solo apuntan hacia adentro. El dominio no sabe que existe Flutter, Supabase ni Hive.

```
Presentation  →  Data  →  Domain
(UI, Riverpod)   (Repos, Hive)   (Entities, contratos)
```

---

## Capa Domain

Es el núcleo. Sin imports de Flutter ni de paquetes externos.

### Entity (ejemplo real: `Transaction`)

```dart
// lib/features/transactions/domain/transaction.dart

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String userId;
  final double amount;       // siempre positivo
  final TransactionType type;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({ ... });

  // Getters de negocio — lógica pura
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome  => type == TransactionType.income;
  double get signedAmount => isExpense ? -amount : amount;

  // Igualdad por id (NO por valor de todos los campos)
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Transaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

**Reglas de las entities:**
- Igualdad manual por `id` — nunca usar `equatable`
- Getters computados para lógica de negocio
- `fromJson`/`toJson` son opcionales aquí — viven mejor en el Model de Data

---

## Capa Data

Implementa los contratos del dominio. Aquí vive todo lo que depende de Hive y Supabase.

### Model (HiveObject + DTO)

En Finpa, el modelo hace dos cosas a la vez: es el objeto que Hive persiste y el DTO que va/viene de Supabase.

```dart
// lib/features/transactions/domain/transaction_model.dart

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(8) bool isSynced;    // ← solo existe localmente
  @HiveField(9) bool isDeleted;   // ← soft-delete local

  // Convierte a entity (dominio puro)
  Transaction toTransaction() { ... }

  // Viene de Supabase (JSON)
  factory TransactionModel.fromJson(Map<String, dynamic> json) { ... }

  // Va hacia Supabase
  Map<String, dynamic> toJson() { ... }

  // Viene de entity (al guardar)
  factory TransactionModel.fromTransaction(Transaction t) { ... }
}
```

### Repository (implementación)

```dart
// lib/features/transactions/data/transaction_repository.dart

class TransactionRepository {
  final SupabaseClient _client;
  final SyncService _syncService;

  Future<List<Transaction>> fetchAll({int? month, int? year}) async {
    // 1. Lee de Hive — instantáneo, sin red
    final local = HiveService.getAllTransactions()
        .where((t) => t.userId == _userId)
        .map((m) => m.toTransaction())
        .toList();

    // 2. Sincroniza en background — NO bloquea
    _syncService.syncAll();

    return local;
  }
}
```

---

## Capa Presentation

Providers Riverpod + Screens + Widgets. Solo habla con la capa Data a través de providers.

### Provider de mutación (patrón del proyecto)

```dart
// lib/features/transactions/providers/transactions_provider.dart

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repo;
  final Ref _ref;

  TransactionNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> add(Transaction t, {String? accountId}) async {
    state = const AsyncLoading();
    try {
      await _repo.add(t, accountId: accountId);
      _ref.invalidate(transactionsProvider); // refresca la lista
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

---

## Qué va en cada capa — guía rápida

| Pregunta | Capa |
|----------|------|
| ¿Es lógica de negocio pura? | Domain |
| ¿Toca Hive o Supabase? | Data |
| ¿Muestra algo en pantalla? | Presentation |
| ¿Es un cálculo sobre datos? | Domain (getter en entity) |
| ¿Es una query con filtros? | Data (repository) |
| ¿Coordina qué mostrar? | Presentation (provider) |

---

## Errores comunes a evitar

```dart
// ❌ MAL: Domain importa Hive
import 'package:hive_flutter/hive_flutter.dart';
class Transaction extends HiveObject { ... }

// ✅ BIEN: Domain es puro, el HiveObject vive en Data
class Transaction { ... }                         // domain
class TransactionModel extends HiveObject { ... } // data

// ❌ MAL: Widget llama directo al repositorio
final repo = TransactionRepository(client);
await repo.add(transaction);

// ✅ BIEN: Widget usa el provider
ref.read(transactionNotifierProvider.notifier).add(transaction);
```
