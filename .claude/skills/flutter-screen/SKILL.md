---
name: flutter-screen
description: This skill should be used when the user asks to "crear pantalla", "crear screen", "nueva pantalla", "agregar screen", "crear widget", or wants to build a Flutter screen with provider, skeleton loading state, dark mode support, and Finpa design system compliance.
version: 1.0.0
---

# Flutter Screen — Finpa

Build complete Flutter screens following the Finpa design system: Riverpod provider, skeleton loading, dark/light mode, and consistent spacing.

## Screen Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class {Name}Screen extends ConsumerWidget {
  const {Name}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch({name}Provider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('{Title}'),
      ),
      body: dataAsync.when(
        loading: () => const _{Name}Skeleton(),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (data) => data.isEmpty
            ? const _EmptyState()
            : _{Name}Content(data: data),
      ),
    );
  }
}
```

## Color Pattern (always use theme, never hardcode)

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final bg          = isDark ? const Color(0xFF0F1320) : Colors.white;
  final border      = isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);
  final textPrimary = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
  final textMuted   = isDark ? const Color(0xFF8892B0) : const Color(0xFF9CA3AF);
  // ...
}
```

## Skeleton Widget Template

Match exact dimensions of real content to avoid layout shift:

```dart
class _{Name}Skeleton extends StatefulWidget {
  const _{Name}Skeleton();

  @override
  State<_{Name}Skeleton> createState() => __{Name}SkeletonState();
}

class __{Name}SkeletonState extends State<_{Name}Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final color = (isDark
                ? const Color(0xFF1E2840)
                : const Color(0xFFE2E6F0))
            .withValues(alpha: 0.5 + _ctrl.value * 0.4);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

## Empty State Template

```dart
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: isDark
                ? const Color(0xFF4A5580)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin datos aún',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFE8EEFF)
                  : const Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega tu primer elemento',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF8892B0)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Card Widget Template

```dart
class _{Name}Card extends StatelessWidget {
  final {Entity} item;
  const _{Name}Card({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1320) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2840)
              : const Color(0xFFE2E6F0),
        ),
      ),
      child: Row(
        children: [
          // content here
        ],
      ),
    );
  }
}
```

## FAB Pattern (main action)

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => context.push('/{route}/add'),
  backgroundColor: const Color(0xFF3B5BDB),
  foregroundColor: Colors.white,
  elevation: 2,
  icon: const Icon(Icons.add, size: 20),
  label: const Text(
    'Agregar',
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  ),
),
```

## Formatting Rules

```dart
// Money — always Bs. with no decimals
static final _moneyFmt = NumberFormat.currency(
  locale: 'es',
  symbol: 'Bs.',
  decimalDigits: 0,
);
String formatted = _moneyFmt.format(amount); // "Bs. 1.500"

// Time
static final _timeFmt = DateFormat('HH:mm');

// Month/Year (manual — no intl for this)
const months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                 'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
String monthYear = '${months[now.month - 1]} ${now.year}';
```

## Design Checklist

Before finishing a screen:

- [ ] Loading state with skeleton (same dimensions as real content)
- [ ] Empty state with icon + message
- [ ] Error state with message
- [ ] Dark mode colors (never hardcoded, always `isDark` check)
- [ ] Padding 16px horizontal consistently
- [ ] Text overflow handled (`maxLines` + `TextOverflow.ellipsis`)
- [ ] No `withOpacity()` — use `withValues(alpha:)` or `withAlpha()`
- [ ] Route registered in `app_router.dart`

## Additional Resources

- **`references/design-tokens.md`** — Complete color palette and spacing reference
