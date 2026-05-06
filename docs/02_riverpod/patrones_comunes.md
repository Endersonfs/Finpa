# Patrones Comunes de Riverpod en Finpa

---

## Patrón 1 — Escuchar errores con ref.listen

Para mostrar snackbars de error sin bloquear la UI:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // listen reacciona a cambios pero NO reconstruye el widget
  ref.listen(transactionNotifierProvider, (_, next) {
    next.whenOrNull(
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      },
    );
  });

  final state = ref.watch(transactionNotifierProvider);
  
  return ElevatedButton(
    onPressed: state.isLoading ? null : () => _save(ref),
    child: state.isLoading
        ? const CircularProgressIndicator()
        : const Text('Guardar'),
  );
}
```

---

## Patrón 2 — when() para AsyncValue

```dart
final transactions = ref.watch(transactionsProvider);

// Completo — maneja los 3 estados
return transactions.when(
  data: (list) => ListView.builder(
    itemCount: list.length,
    itemBuilder: (_, i) => TransactionTile(transaction: list[i]),
  ),
  loading: () => const TransactionListShimmer(),
  error: (e, _) => ErrorState(message: e.toString()),
);

// Parcial — solo algunos estados
return transactions.whenOrNull(
  data: (list) => Text('${list.length} transacciones'),
);

// Con skipLoadingOnRefresh — no muestra shimmer en refrescos
return transactions.when(
  skipLoadingOnRefresh: true,
  data: (list) => ...,
  loading: () => ...,
  error: (e, _) => ...,
);
```

---

## Patrón 3 — ref.watch vs ref.read

```dart
// ref.watch — reactivo, reconstruye el widget cuando cambia
// Usar en build()
final theme = ref.watch(themeProvider);

// ref.read — lee una sola vez, no reactivo
// Usar en callbacks (onPressed, initState)
onPressed: () => ref.read(themeProvider.notifier).toggle(),

// ❌ NUNCA usar ref.read en build() — no detectará cambios
// ❌ NUNCA usar ref.watch en callbacks — puede causar errores
```

---

## Patrón 4 — Inyectar SharedPreferences antes de runApp

Hay providers que necesitan `SharedPreferences` sincronamente. La solución es inyectarlo via `ProviderScope.overrides`:

```dart
// main.dart
void main() async {
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const FinPaApp(),
    ),
  );
}

// El provider lanza si no fue sobreescrito (error claro en desarrollo)
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Must be overridden'),
);
```

---

## Patrón 5 — Invalidar dependencias en cascada

Cuando una mutación afecta múltiples listas:

```dart
Future<void> add(Transaction t, {String? accountId}) async {
  await _repo.add(t, accountId: accountId);

  // Invalida todo lo que depende de esta transacción
  _ref.invalidate(transactionsProvider);      // lista de transacciones
  _ref.invalidate(dashboardSummaryProvider);  // resumen del dashboard
  if (accountId != null) {
    _ref.invalidate(accountsStreamProvider);  // saldo de la cuenta
  }
}
```

---

## Patrón 6 — Extensión tr() para traducciones

En lugar de `ref.watch(languageNotifierProvider).translate('key')`, hay una extensión:

```dart
// Definida en lib/core/providers/language_provider.dart
extension Trans on WidgetRef {
  String tr(String key) => watch(languageNotifierProvider).translate(key);
}

// Uso en cualquier ConsumerWidget
Text(ref.tr('dashboard.balance'))
Text(ref.tr('transactions.add_title'))
```

Las claves usan notación de punto para objetos anidados en el JSON:
```json
{
  "dashboard": {
    "balance": "Saldo total"
  }
}
```

---

## Anti-patrones a evitar

```dart
// ❌ Lógica de negocio en el widget
onPressed: () {
  final amount = double.parse(controller.text);
  if (amount > 0) {
    // calcular cosas...
    setState(() { ... });
  }
}

// ✅ Delegar al notifier
onPressed: () => ref.read(transactionNotifierProvider.notifier).add(t);

// ❌ Crear instancias directamente en el widget
final repo = TransactionRepository(Supabase.instance.client);

// ✅ Usar provider
final repo = ref.read(transactionRepositoryProvider);

// ❌ StateNotifier para estado local de UI (ej: si un checkbox está marcado)
// ✅ Para estado local de UI usar StatefulWidget o local variable en ConsumerStatefulWidget
```
