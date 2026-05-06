# Design System — FinPa

---

## Colores

Los colores **nunca se usan directamente** de las clases internas (`_Light`, `_Dark`). Se accede siempre a través del tema o la extensión `FinPaColors`.

### Colores del tema (Material 3)
```dart
final cs = Theme.of(context).colorScheme;

cs.primary          // verde principal #2F7155
cs.surface          // fondo de cards
cs.onSurface        // texto principal
cs.onSurfaceVariant // texto secundario
cs.outline          // bordes
cs.error            // rojo de error/gastos
```

### Colores semánticos — extensión FinPaColors
Para colores que no existen en Material (income, expense, muted, etc.):

```dart
final c = Theme.of(context).extension<FinPaColors>()!;

c.income   // verde ingreso  (light: #059669 / dark: #34D399)
c.expense  // rojo gasto     (light: #DC2626 / dark: #F87171)
c.warning  // amarillo alerta
c.cardBg   // fondo de cards secundarios
c.border   // color de bordes
c.muted    // texto muy tenue
```

### Paleta completa

| Token | Light | Dark |
|-------|-------|------|
| `scaffoldBg` | `#F5F6FA` | `#0A0D14` |
| `surface` | `#FFFFFF` | `#0F1320` |
| `cardBg` | `#F0F2F8` | `#141928` |
| `border` | `#E2E6F0` | `#1E2840` |
| `primary` | `#2F7155` | `#2F7155` |
| `income` | `#059669` | `#34D399` |
| `expense` | `#DC2626` | `#F87171` |
| `textPrimary` | `#1A1F36` | `#E8EEFF` |
| `textSecond` | `#6B7280` | `#8892B0` |
| `muted` | `#9CA3AF` | `#4A5580` |

### ❌ Nunca hacer esto
```dart
// NO hardcodear colores
Container(color: const Color(0xFFF5F6FA))  // rompe dark mode

// NO usar withOpacity()
color.withOpacity(0.5)  // deprecado

// ✅ Usar siempre
Theme.of(context).scaffoldBackgroundColor
color.withAlpha(128)      // equivalente a opacity 0.5
color.withValues(alpha: 0.5)
```

---

## Tipografía

La fuente es **Inter** via `google_fonts`. Viene configurada en `AppTheme` y se hereda automáticamente. Para estilos personalizados:

```dart
GoogleFonts.inter(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: Theme.of(context).colorScheme.onSurface,
)

// O usar los estilos del tema directamente (recomendado)
Theme.of(context).textTheme.titleMedium
Theme.of(context).textTheme.bodySmall
```

---

## Espaciado y bordes

```dart
// Padding horizontal — siempre 16px
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: ...,
)

// Cards pequeñas
BorderRadius.circular(12)

// Cards grandes
BorderRadius.circular(16)

// Bottom sheets
BorderRadius.vertical(top: Radius.circular(24))
```

---

## Botones

Los estilos vienen del tema. Solo hace falta usar los widgets correctos:

```dart
// Primario — acción principal de la pantalla
ElevatedButton(
  onPressed: ...,
  child: const Text('Guardar'),
  // mínimo 52px de alto, ancho completo, radius 12 — automático del tema
)

// Secundario — acción alternativa
OutlinedButton(
  onPressed: ...,
  child: const Text('Cancelar'),
)
```

---

## Cards

```dart
// Card básica — usa el tema automáticamente
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: ...,
  ),
)

// Card con color customizado (FinPaColors)
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).extension<FinPaColors>()!.cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Theme.of(context).extension<FinPaColors>()!.border,
    ),
  ),
  child: ...,
)
```

---

## Inputs (formularios)

Los estilos vienen del tema. Solo usar `TextFormField`:

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: ref.tr('transactions.amount'),
    prefixText: 'Bs. ',
    // El borde, colores y radio ya vienen del InputDecorationTheme
  ),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
)
```

---

## Montos de dinero

```dart
// Para mostrar montos siempre con el mismo formato
import 'package:intl/intl.dart';

final formatter = NumberFormat.currency(
  locale: 'es',
  symbol: 'Bs.',
  decimalDigits: 0,
);

formatter.format(1234567) // → "Bs. 1.234.567"

// Widget utilitario del proyecto
CompactAmountText(amount: transaction.amount, isExpense: true)
```

---

## AppBar estándar

```dart
AppBar(
  title: Text(ref.tr('transactions.title')),
  // centerTitle, elevation=0, colores — automático del tema
  actions: [
    IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: ...,
    ),
  ],
)
```
