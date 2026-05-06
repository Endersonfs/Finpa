# Tipos de Providers en Finpa

Finpa usa Riverpod 2.x con una mezcla de providers manuales y generados con `@Riverpod`.

---

## Provider simple — dependencias y servicios

Para exponer una instancia que no cambia. Equivalente a un singleton con inyección de dependencias.

```dart
// Exponer el repositorio
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(Supabase.instance.client);
});

// Exponer SharedPreferences (inyectado desde main.dart)
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Must be overridden in ProviderScope'),
);
```

---

## FutureProvider — dato asíncrono que se carga una vez

```dart
// Lee una vez y devuelve el resultado
final dashboardSummaryProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  return repo.monthlySummary(month: now.month, year: now.year);
});
```

Uso en widget:
```dart
final summary = ref.watch(dashboardSummaryProvider);

return summary.when(
  data: (data) => Text('Ingresos: ${data['income']}'),
  loading: () => const ShimmerBox(height: 40),
  error: (e, _) => const ErrorState(),
);
```

---

## StreamProvider — dato que cambia en tiempo real

```dart
// Se re-emite cada vez que Hive cambia
final transactionsProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  return repo.watchAll(month: now.month, year: now.year);
});
```

El `StreamProvider` se actualiza automáticamente cuando el repositorio emite nuevos valores via `HiveService.transactionsBox.watch()`.

---

## StateNotifierProvider — mutaciones con estado de carga

Para operaciones de escritura (add, delete, update). Expone un `AsyncValue<void>` que la UI puede observar para mostrar loading/error.

```dart
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

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>(
  (ref) => TransactionNotifier(
    ref.watch(transactionRepositoryProvider),
    ref,
  ),
);
```

Uso en widget para manejar el estado de guardado:
```dart
ref.listen(transactionNotifierProvider, (_, next) {
  next.whenOrNull(
    error: (e, _) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString()))),
  );
});
```

---

## NotifierProvider (Riverpod 2.x moderno) — con @Riverpod

Para providers más complejos con código generado. El `ThemeNotifier` usa este patrón:

```dart
// Anotar con @Riverpod para generar themeProvider automáticamente
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPrefsProvider);
    return _fromString(prefs.getString(_kThemeKey));
  }

  void toggle() => _save(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
```

Correr `dart run build_runner build` para generar `theme_provider.g.dart`.

---

## autoDispose — liberar memoria automáticamente

```dart
// Se destruye cuando no hay widgets escuchando
final budgetsProvider = StreamProvider.autoDispose<List<Budget>>((ref) { ... });

// keepAlive: el provider persiste aunque no haya listeners
@Riverpod(keepAlive: true)
class LanguageNotifier extends _$LanguageNotifier { ... }
```

**Regla general:** usar `autoDispose` para datos de pantalla, `keepAlive: true` para configuración global (tema, idioma, prefs).

---

## invalidate vs refresh

```dart
// invalidate — destruye el provider y lo recrea en el próximo watch
_ref.invalidate(transactionsProvider);

// refresh — fuerza recarga inmediata (sin esperar un watch)
_ref.refresh(transactionsProvider);
```

En Finpa se usa `invalidate` después de mutaciones (add/delete) para que los `StreamProvider` y `FutureProvider` que muestran listas se recarguen.

---

## Resumen — cuándo usar cada uno

| Provider | Cuándo usarlo |
|----------|--------------|
| `Provider` | Servicios, repositorios, instancias estáticas |
| `FutureProvider` | Carga inicial de datos, queries de una vez |
| `StreamProvider` | Datos reactivos que cambian (Hive watchers) |
| `StateNotifierProvider` | Mutaciones (add/edit/delete) con estado loading/error |
| `NotifierProvider` (@Riverpod) | Estado complejo con múltiples métodos |
