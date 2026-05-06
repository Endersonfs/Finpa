# Skeleton Loading con ShimmerBox

El shimmer es la pantalla de carga esqueleto — muestra cajas animadas mientras los datos llegan, en lugar de un spinner genérico.

---

## Widget base — ShimmerBox

```dart
// lib/core/widgets/shimmer_box.dart

ShimmerBox(
  width: 200,          // null = ancho máximo disponible
  height: 16,          // obligatorio
  radius: 8,           // radio de bordes (default 8)
)
```

Adapta sus colores automáticamente al tema dark/light.

---

## Shimmers pre-construidos del proyecto

```dart
// Fila de transacción (icono + dos líneas de texto + monto)
const TransactionTileShimmer()

// Tarjeta de balance del dashboard (caja grande)
const BalanceCardShimmer()

// Tarjeta de meta de ahorro
const GoalCardShimmer()

// Item de presupuesto
const BudgetItemShimmer()
```

---

## Cómo mostrar shimmer mientras carga un AsyncValue

```dart
final transactions = ref.watch(transactionsProvider);

return transactions.when(
  loading: () => Column(
    children: List.generate(5, (_) => const TransactionTileShimmer()),
  ),
  data: (list) => ListView.builder(
    itemCount: list.length,
    itemBuilder: (_, i) => TransactionTile(transaction: list[i]),
  ),
  error: (e, _) => ErrorState(message: e.toString()),
);
```

---

## Crear un shimmer para un widget nuevo

Sigue este patrón — el shimmer imita la estructura del widget real:

```dart
// Widget real
class AccountCard extends StatelessWidget {
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(account.name, style: ...),        // línea 1 — nombre
          const SizedBox(height: 8),
          Text(formatter.format(account.balance)), // línea 2 — saldo
        ],
      ),
    );
  }
}

// Shimmer equivalente — misma estructura, cajas en lugar de texto
class AccountCardShimmer extends StatelessWidget {
  const AccountCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 120, height: 14, radius: 6),  // nombre
          const SizedBox(height: 8),
          ShimmerBox(width: 80, height: 18, radius: 6),   // saldo
        ],
      ),
    );
  }
}
```

---

## Lista de shimmers mientras no hay datos

```dart
// Para listas de longitud desconocida — mostrar N skeletons
ListView.builder(
  itemCount: 4,
  itemBuilder: (_, __) => const TransactionTileShimmer(),
)

// Para grids
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.5,
  ),
  itemCount: 6,
  itemBuilder: (_, __) => const ShimmerBox(height: 100, radius: 12),
)
```

---

## Por qué shimmer en lugar de spinner

| Spinner | Shimmer |
|---------|---------|
| El usuario no sabe cuánto esperar | Comunica el tamaño de lo que viene |
| Sensación de lentitud | Sensación de rapidez (la app "ya sabe" qué mostrar) |
| Un solo punto de carga | Carga distribuida por sección |
| Genérico | Coherente con el diseño de la app |
