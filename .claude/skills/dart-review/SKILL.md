---
name: dart-review
description: This skill should be used when the user asks to "revisar código", "review código", "mejorar código dart", "código más idiomático", "optimizar dart", "revisar dart", or wants a Dart code quality review focusing on null safety, idiomatic patterns, performance, and Dart 3 features in the Finpa project.
version: 1.0.0
---

# Dart Review — Finpa

Review Dart code for quality, idiomatic patterns, null safety, and Dart 3 features. Focus on what matters for a production Flutter app.

## Review Checklist

Run through each category when reviewing:

### 1. Null Safety
- [ ] No unnecessary `!` (null assertion) — use `??`, `?.`, or guard clauses
- [ ] No `dynamic` except for raw JSON parsing
- [ ] `late` only when initialization is guaranteed before first use
- [ ] Nullable types declared explicitly (`String?` not `String`)

```dart
// ❌ Bad
final name = user!.displayName!;

// ✅ Good
final name = user?.displayName ?? 'Usuario';
```

### 2. Const and Final
- [ ] `const` constructors where all fields are compile-time constants
- [ ] `final` for all variables that don't reassign
- [ ] `const` for widget constructors when possible

```dart
// ❌ Bad
var total = 0.0;
Text('Hola')

// ✅ Good
final total = items.fold(0.0, (sum, item) => sum + item.amount);
const Text('Hola')
```

### 3. Collections
- [ ] Prefer functional methods over imperative loops
- [ ] Use `whereType<T>()` instead of `where((e) => e is T).cast<T>()`
- [ ] Use `firstOrNull` / `lastOrNull` instead of try/catch on `first`

```dart
// ❌ Bad
double total = 0;
for (final t in transactions) {
  if (t.isExpense) total += t.amount;
}

// ✅ Good
final total = transactions
    .where((t) => t.isExpense)
    .fold(0.0, (sum, t) => sum + t.amount);
```

### 4. Async / Await
- [ ] No `Future.then()` chains — use `async/await`
- [ ] `unawaited()` for fire-and-forget calls
- [ ] Error handling with try/catch at the boundary (provider or datasource)

```dart
// ❌ Bad
repo.getAll().then((data) {
  setState(() => items = data);
}).catchError((e) => print(e));

// ✅ Good
try {
  final data = await repo.getAll();
  state = AsyncValue.data(data);
} catch (e, st) {
  state = AsyncValue.error(e, st);
}
```

### 5. Dart 3 Features
- [ ] Pattern matching with `switch` expressions where it simplifies code
- [ ] Records for returning multiple values instead of Maps
- [ ] `sealed class` for exhaustive state modeling

```dart
// ❌ Bad (Dart 2 style)
String label(TransactionType type) {
  if (type == TransactionType.income) return 'Ingreso';
  return 'Gasto';
}

// ✅ Good (Dart 3)
String label(TransactionType type) => switch (type) {
  TransactionType.income  => 'Ingreso',
  TransactionType.expense => 'Gasto',
};
```

### 6. Class Design
- [ ] No public mutable fields — use getters or `final`
- [ ] Computed getters for derived values instead of methods with no params
- [ ] Extensions for behavior that doesn't belong in the class

```dart
// ❌ Bad
double getSignedAmount(Transaction t) {
  return t.isExpense ? -t.amount : t.amount;
}

// ✅ Good — computed getter on entity
double get signedAmount => isExpense ? -amount : amount;

// ✅ Good — extension for formatting (not core logic)
extension TransactionFormatting on Transaction {
  String get formattedAmount =>
      NumberFormat.currency(locale: 'es', symbol: 'Bs.', decimalDigits: 0)
          .format(amount);
}
```

### 7. Riverpod Specific
- [ ] `FutureProvider.autoDispose` for data that should refresh
- [ ] `ref.invalidate()` instead of manual state resets
- [ ] No `ref.read()` inside `build()` — only `ref.watch()`
- [ ] `ref.read()` only in callbacks and actions

```dart
// ❌ Bad
Widget build(BuildContext context, WidgetRef ref) {
  final data = ref.read(myProvider); // won't rebuild!
}

// ✅ Good
Widget build(BuildContext context, WidgetRef ref) {
  final data = ref.watch(myProvider); // rebuilds on change
}
```

### 8. Flutter / Widget Specific
- [ ] `const` widgets wherever possible
- [ ] Split large `build()` methods into private widgets or methods
- [ ] No business logic in `build()` — compute in providers
- [ ] `AnimationController` always disposed in `dispose()`

## Common Patterns to Suggest

### Safe list access
```dart
// Instead of try/catch on .first
final first = list.firstOrNull;
final byId = list.where((e) => e.id == id).firstOrNull;
```

### Group by category
```dart
final byCategory = <String, List<Transaction>>{};
for (final t in transactions) {
  (byCategory[t.categoryId] ??= []).add(t);
}

// Or with package:collection
final byCategory = transactions.groupListsBy((t) => t.categoryId);
```

### Date helpers
```dart
extension DateTimeX on DateTime {
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  DateTime get startOfMonth => DateTime(year, month);
  DateTime get endOfMonth   => DateTime(year, month + 1, 0, 23, 59, 59);
}
```

## Review Output Format

When reviewing code, report findings grouped by severity:

```
### 🔴 Crítico (bugs o crashes potenciales)
- [archivo:línea] Descripción del problema → Sugerencia de fix

### 🟡 Mejora (código no idiomático)
- [archivo:línea] Descripción → Versión mejorada

### 🟢 Estilo (menor, opcional)
- [archivo:línea] Sugerencia
```

## Additional Resources

- **`references/dart3-patterns.md`** — Dart 3 sealed classes, records, and pattern matching examples
