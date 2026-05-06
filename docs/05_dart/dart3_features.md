# Dart 3 — Features usadas en Finpa

---

## Pattern Matching con switch

Dart 3 permite usar `switch` como expresión y con pattern matching.

### Switch expression (usado en ThemeNotifier)
```dart
// lib/core/providers/theme_provider.dart

// Switch como expresión (retorna un valor)
static ThemeMode _fromString(String? value) => switch (value) {
  'dark'   => ThemeMode.dark,
  'system' => ThemeMode.system,
  _        => ThemeMode.light,  // wildcard — default
};

void _save(ThemeMode mode) {
  _prefs.setString(_kThemeKey, switch (mode) {
    ThemeMode.light  => 'light',
    ThemeMode.dark   => 'dark',
    ThemeMode.system => 'system',
  });
}
```

### Cuándo usar switch expression vs if-else
```dart
// ✅ Switch expression — cuando mapeas un valor a otro
final label = switch (type) {
  TransactionType.income  => 'Ingreso',
  TransactionType.expense => 'Gasto',
};

// ✅ if-else — cuando la condición es compleja o tiene efectos
if (amount > 0 && category.isNotEmpty) {
  await repo.add(transaction);
}
```

---

## Null Safety — patrones del proyecto

```dart
// Operador null-aware ?.
final name = user?.userMetadata?['full_name'] as String?;

// Operador ?? — valor por defecto
final lang = prefs.getString('app_language') ?? 'es';
final balance = account?.balance ?? 0.0;

// Operador ??= — asignar solo si es null
cache ??= await loadFromDisk();

// Assertion ! — solo cuando se está seguro
final userId = _client.auth.currentUser!.id;
// ↑ solo usar cuando el código garantiza que hay sesión activa

// late — inicialización diferida garantizada
late final AnimationController _ctrl; // se asigna en initState
```

---

## Abstract final class — clases utilitarias

Para clases que solo tienen miembros estáticos y no deben ser instanciadas:

```dart
// lib/core/theme/app_theme.dart
abstract final class AppTheme {
  static ThemeData get light => ThemeData(...);
  static ThemeData get dark  => ThemeData(...);
  // No se puede instanciar: AppTheme()  ← error de compilación
}

// lib/core/theme/app_theme.dart — paleta interna
abstract final class _Light {
  static const primary = Color(0xFF2F7155);
  static const income  = Color(0xFF059669);
}
```

---

## Records (Dart 3.0+)

Útiles para retornar múltiples valores sin crear una clase:

```dart
// Ejemplo de uso potencial en Finpa
(double income, double expense) getSummary(List<Transaction> transactions) {
  final income = transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);
  final expense = transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
  return (income, expense);
}

// Destructuring al usar
final (income, expense) = getSummary(transactions);
```

---

## Sealed classes (Dart 3.0+)

Para modelar estados exhaustivos. Útil para errores tipados:

```dart
// Un AppException exhaustivo con sealed class
sealed class AppException implements Exception {
  const AppException();
}

class NetworkException extends AppException {
  final String message;
  const NetworkException(this.message);
}

class AuthException extends AppException {
  final String code;
  const AuthException(this.code);
}

class NotFoundException extends AppException {
  const NotFoundException();
}

// El compilador verifica que todos los casos están cubiertos
String handleError(AppException e) => switch (e) {
  NetworkException(:final message) => 'Red: $message',
  AuthException(:final code)       => 'Auth: $code',
  NotFoundException()              => 'No encontrado',
  // No necesita default — el compilador sabe que son todos los casos
};
```

---

## Extension methods — el patrón Trans

```dart
// lib/core/providers/language_provider.dart
extension Trans on WidgetRef {
  String tr(String key) => watch(languageNotifierProvider).translate(key);
}

// Uso
ref.tr('dashboard.balance')
// En lugar de: ref.watch(languageNotifierProvider).translate('dashboard.balance')
```

Otro ejemplo: extensión para formatear montos:
```dart
extension on double {
  String toMoney() => NumberFormat.currency(
    locale: 'es',
    symbol: 'Bs.',
    decimalDigits: 0,
  ).format(this);
}

// Uso
Text(transaction.amount.toMoney()) // → "Bs. 1.500"
```

---

## const constructors — performance

```dart
// ✅ Usar const cuando el widget no depende de datos dinámicos
const TransactionTileShimmer()
const SizedBox(height: 16)
const EdgeInsets.symmetric(horizontal: 16)

// Flutter evita reconstruir widgets const si el padre se reconstruye
// → menos trabajo para el motor de renderizado
```
