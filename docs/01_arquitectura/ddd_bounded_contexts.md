# DDD — Bounded Contexts en Finpa

## Qué es un Bounded Context

Es una frontera explícita dentro del sistema donde un modelo y sus términos tienen un significado específico. En Finpa, cada feature de `lib/features/` es un bounded context.

## Bounded contexts del proyecto

| Context | Responsabilidad | Entity principal |
|---------|----------------|-----------------|
| `transactions` | Registrar ingresos y gastos | `Transaction` |
| `accounts` | Cuentas bancarias y saldos | `AccountModel` |
| `budget` | Presupuestos mensuales por categoría | `Budget` |
| `goals` | Metas de ahorro con progreso | `SavingGoal` |
| `auth` | Sesión, biometría, seguridad | `User` (Supabase) |
| `ai_chat` | Asistente financiero con IA | `Message` |
| `education` | Lecciones y módulos financieros | `Lesson`, `Module` |
| `reports` | Análisis y gráficas de gastos | (derivado de transactions) |

---

## Estructura interna de un context

```
lib/features/transactions/
  data/
    transaction_repository.dart   ← implementación concreta
  domain/
    transaction.dart              ← entity pura
    transaction_model.dart        ← HiveObject + DTO
  presentation/
    providers/
      transactions_provider.dart  ← StreamProvider (lista)
      transaction_provider.dart   ← repositorio provider + notifier
    screens/
      transactions_screen.dart
      add_transaction_screen.dart
      transaction_detail_screen.dart
    widgets/
      (componentes internos del feature)
```

---

## Reglas de comunicación entre contexts

Los bounded contexts **no se importan directamente entre sí**. La comunicación se hace a través de providers de Riverpod o a nivel de datos (Hive).

### ✅ Correcto — comunicación via Hive
```dart
// En transaction_repository.dart — al agregar una transacción:
// actualiza el saldo de la cuenta ACCEDIENDO A HIVE directamente
final account = HiveService.accountsBox.get(accountId);
await HiveService.saveAccount(account.copyWith(balance: newBalance));
```

### ✅ Correcto — comunicación via provider invalidation
```dart
// En TransactionNotifier.add():
await _repo.add(t, accountId: accountId);
_ref.invalidate(transactionsProvider);
_ref.invalidate(accountsStreamProvider); // ← invalida el otro context
```

### ❌ Incorrecto — importar repository de otro context
```dart
// NO hacer esto en transaction_repository.dart:
import '../../accounts/data/accounts_repository.dart';
final accountRepo = AccountsRepository(client);
await accountRepo.updateBalance(...);
```

---

## Value Objects (objetos de valor)

Son objetos definidos por sus atributos, no por identidad. En Finpa se usan implícitamente:

```dart
// TransactionType es un value object simple (enum)
enum TransactionType { income, expense }

// AccountType también
enum AccountType { checking, savings, cash, credit, investment }
```

Para value objects más complejos (como un Money con divisa), el patrón sería:
```dart
class Money {
  final double amount;
  final String currency;

  const Money(this.amount, this.currency);

  @override
  bool operator ==(Object other) =>
      other is Money && amount == other.amount && currency == other.currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}
```

---

## Cómo agregar un nuevo Bounded Context

1. Crear la carpeta `lib/features/{nombre}/`
2. Definir la entity en `domain/{nombre}.dart` (sin dependencias externas)
3. Crear el `HiveType` en `domain/{nombre}_model.dart` con el siguiente `typeId` disponible
4. Registrar el adapter en `HiveService._registerAdapters()`
5. Implementar el repository en `data/{nombre}_repository.dart`
6. Crear providers en `presentation/providers/`
7. Correr `dart run build_runner build --delete-conflicting-outputs`
8. Agregar rutas en `router/app_router.dart`

> Usar el skill `/add-feature` en Claude Code para que haga este proceso guiado.
