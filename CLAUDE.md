# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Finpa - Contexto del Proyecto

## Qué es Finpa
Aplicación móvil financiera personal desarrollada en Flutter.
Plataformas: Android e iOS.

## Comandos Comunes

```bash
# Ejecutar en modo debug
flutter run

# Análisis estático
flutter analyze

# Tests
flutter test
flutter test test/path/to/file_test.dart   # Un solo archivo

# Build
flutter build apk
flutter build appbundle
flutter build ios

# Generación de código (Hive adapters + Riverpod providers)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
```

> Siempre correr `build_runner` después de agregar/modificar clases `@HiveType` o providers `@Riverpod`.

## Arquitectura: Clean Architecture + DDD

### Capas (de adentro hacia afuera)
```
Domain → Data → Presentation
```

1. **Domain** (núcleo, sin dependencias externas)
   - Entities/models — Objetos de negocio puros (igualdad manual por `id`)
   - `repositories/` — Interfaces (contratos) que define el dominio

2. **Data** (implementaciones)
   - Models — DTOs que también son `HiveObject` (ver abajo), con `fromJson`/`toJson` + conversión a entity
   - `repositories/` — Implementaciones concretas que usan Hive + SyncService

3. **Presentation** (UI)
   - `providers/` — Riverpod: `FutureProvider`, `NotifierProvider`, etc.
   - Pantallas (sufijo `Screen`), widgets reutilizables

### Estructura de Carpetas
```
lib/
  core/
    theme/            # AppTheme, FinPaColors
    providers/        # theme_provider, language_provider, currency_provider
    local_storage/    # HiveService (puerta de entrada a Hive), SyncMetadata
    network/          # SyncService (upload/download Supabase ↔ Hive)
    widgets/          # Widgets compartidos
  features/
    {feature}/
      data/
        {feature}_repository.dart   # Implementación (Hive-first)
      domain/
        {feature}_model.dart        # Entity + HiveObject en uno
      presentation/
        providers/
        screens/
        widgets/
  router/
    app_router.dart   # GoRouter con redirect guard (auth + lock)
    main_shell.dart   # NavigationBar con 5 tabs
  main.dart
  app.dart
```

## Arquitectura Offline-First (CRÍTICO)

La app es **Local-First**: Hive es la fuente de verdad, Supabase es el backend de sincronización.

### Flujo de escritura
1. Guardar en Hive inmediatamente (`isSynced: false`)
2. Llamar `_syncService.syncAll()` **sin await** (no bloquea UI)
3. SyncService sube los registros pendientes a Supabase en segundo plano

### Flujo de lectura
1. Leer de Hive (instantáneo, sin esperar red)
2. Disparar `_syncService.syncAll()` en segundo plano para actualizar datos

### Soft-delete
Los registros nunca se borran de Hive directamente. Se marcan con `isDeleted = true` y `isSynced = false`. El SyncService los elimina en Supabase y luego se pueden limpiar localmente.

### Cajas Hive
| Box | Tipo | TypeId |
|-----|------|--------|
| `transactions` | `TransactionModel` | 0 |
| `sync_metadata` | `SyncMetadata` | 1 |
| `accounts` (AccountType enum) | — | 2 |
| `accounts` | `AccountModel` | 3 |
| `budgets` | `Budget` | 4 |
| `goals` | `SavingGoal` | 5 |

> **IMPORTANTE**: Los TypeIds de Hive son globales y deben ser únicos. Al agregar un nuevo `@HiveType`, usar el siguiente número disponible (6, 7…) y nunca reutilizar IDs existentes.

## Modelos como HiveObject

A diferencia de DDD puro, los modelos en este proyecto son simultáneamente DTOs y objetos Hive:

```dart
@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) final String id;
  // ...

  Transaction toTransaction() { ... }             // conversión a entity
  factory TransactionModel.fromJson(Map json) ... // desde Supabase
  Map<String, dynamic> toJson() ...               // hacia Supabase
  factory TransactionModel.fromTransaction(Transaction t) ...
}
```

Los campos `isSynced` y `isDeleted` solo existen en el modelo (Hive), no en Supabase.

## Sistema de Traducciones

Los archivos JSON viven en `assets/translations/es.json` y `en.json`. En widgets se usa la extensión `Trans`:

```dart
// En un ConsumerWidget:
ref.tr('dashboard.balance')   // → lee languageNotifierProvider
```

Las claves usan notación de punto para acceder a objetos anidados. El idioma default es `'es'`.

## Reglas de Arquitectura (OBLIGATORIAS)

1. **Domain nunca importa de Data ni Presentation**
2. **Providers Riverpod manejan TODO el estado** — no lógica en widgets
3. **No instanciar clases directamente en widgets** — usar providers
4. **Modelos tienen `fromJson`/`toJson`** y método de conversión a entity
5. **Supabase solo accesible desde la capa Data** (repositories/SyncService)
6. **Hive es la fuente de verdad** — nunca await Supabase para mostrar datos en UI

## Convenciones de Código

### Nombrado
- Archivos: `snake_case` — `add_transaction_screen.dart`, `budget_repository.dart`
- Clases y enums: `PascalCase` — `TransactionModel`, `TransactionType`
- Variables, funciones y providers: `camelCase` — `fetchAll()`, `transactionsProvider`
- Entities: `Transaction`, `Budget`, `SavingGoal`
- Modelos/HiveObject: `TransactionModel`, `AccountModel`
- Repositorios (impl): `TransactionRepository`, `AccountsRepository`
- Providers: `transactionsProvider`, `budgetProvider`
- Pantallas: sufijo `Screen` — `DashboardScreen`, `AddTransactionScreen`

### Tamaño de widgets
Si un widget supera **100 líneas**, extraerlo a su propio archivo en `widgets/` dentro del feature. Los archivos de screen solo deben orquestar, no contener widgets inline grandes.

```dart
// ❌ MAL: widget de 150 líneas inline en la screen
class TransactionsScreen extends ConsumerWidget {
  Widget build(context, ref) {
    return Column(children: [
      // ...150 líneas de FilterBar inline...
    ]);
  }
}

// ✅ BIEN: extraído a su propio archivo
// lib/features/transactions/presentation/widgets/filter_bar.dart
class FilterBar extends StatelessWidget { ... }
```

### Comentarios en código
Documentar **el por qué**, nunca el qué. Solo en funciones complejas o decisiones arquitectónicas no obvias.

```dart
// ❌ MAL: documenta lo que el nombre ya dice
/// Retorna todas las transacciones del usuario
Future<List<Transaction>> fetchAll() async { ... }

// ✅ BIEN: explica una decisión no obvia
// Disparamos sync sin await para no bloquear la UI — el usuario
// ve datos locales instantáneamente aunque estén ligeramente desactualizados.
_syncService.syncAll();

// ✅ BIEN: explica una restricción oculta
// typeId 2 está reservado para AccountType (enum) aunque ya no use @HiveType.
// Reutilizarlo causaría corrupción silenciosa al abrir cajas viejas.
if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountModelAdapter());
```

## Seguridad

### Credenciales y variables de entorno
- **Nunca** hardcodear claves de Supabase, Anthropic ni ninguna API key en el código
- Todas las credenciales van en `.env` (ya está en `.gitignore`)
- El `.env` se carga en `main.dart` via `flutter_dotenv` antes de cualquier inicialización

Variables requeridas en `.env`:
```
SUPABASE_URL=https://xxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ANTHROPIC_API_KEY=sk-ant-...
```

Si alguna variable está vacía, la feature correspondiente se deshabilita gracefully (no lanza excepción en producción).

### Sanitización de entradas
Antes de enviar cualquier dato de un `TextFormField` a Supabase o a la API de IA, sanitizar:

```dart
// Trim en strings de usuario
final name = controller.text.trim();

// Validar en el formulario antes de procesar
if (name.isEmpty || name.length < 2) {
  // mostrar error de validación, no continuar
  return;
}

// Parsear números de forma segura
final amount = double.tryParse(amountController.text);
if (amount == null || amount <= 0) return;
```

### Logging de errores sin datos sensibles
```dart
// ❌ MAL: expone datos del usuario en el log
debugPrint('Error al guardar transacción del usuario ${user.email}: $e');

// ✅ BIEN: loguea el contexto técnico, no los datos
debugPrint('TransactionRepository.add falló: ${e.runtimeType}');
```

## Documentación

El README del proyecto debe incluir: descripción, requisitos, pasos de configuración del `.env`, cómo correr el proyecto y los tests. Sin esa información un colaborador nuevo no puede arrancar.

Solo agregar comentarios en código cuando el **por qué** es no obvio: restricciones ocultas, invariantes sutiles, workarounds para bugs específicos, decisiones arquitectónicas con tradeoffs. Ver la sección "Comentarios en código" arriba.

La carpeta `docs/` contiene documentación de estudio y referencia organizada por área (arquitectura, Riverpod, UI, backend, testing). Actualizar cuando cambie algún patrón establecido.

## Stack Técnico
- Flutter 3.x / Dart 3.10
- State: **flutter_riverpod ^2.5.1** + `riverpod_annotation` (codegen con `@Riverpod`)
- Backend: `supabase_flutter ^2.5.3`
- Routing: `go_router ^13.x` — `routerProvider` en `router/app_router.dart`
- Local: `hive_flutter ^1.1.0` + `shared_preferences` + `flutter_secure_storage`
- Charts: `fl_chart`
- Biometría: `local_auth`
- Env: `flutter_dotenv` (archivo `.env` con `SUPABASE_URL` y `SUPABASE_ANON_KEY`)

## Patrones de UI

- Padding horizontal: **16px** siempre
- BorderRadius: 12px cards, 16px cards grandes
- Fuente: Inter via `google_fonts`
- Montos: `NumberFormat.currency(locale: 'es', symbol: 'Bs.', decimalDigits: 0)`
- **NO usar `withOpacity()`** — usar `withValues(alpha: x)` o `withAlpha(x)`
- Colores custom: `Theme.of(context).extension<FinPaColors>()!`
- Tema default: `ThemeMode.light`
- Skeleton/loading: usar `ShimmerBox` de `core/widgets/`

## Auth y Navegación

El router en `app_router.dart` maneja tres guards en `redirect`:
1. Onboarding (`finpa_onboarding_done` en SharedPreferences)
2. Sesión Supabase (usuario nulo → `/auth/login`)
3. Lock de sesión (biométrico — `sessionProvider.isLocked` → `/lock`)

Las rutas dentro del shell (5 tabs) son: `/dashboard`, `/transactions`, `/budget`, `/goals`, `/chat`. Las rutas secundarias (sin shell) incluyen `/accounts`, `/reports`, `/education`, `/profile`, `/settings`.

## Sub-agentes disponibles
- `flutter-architect` — decisiones de arquitectura, estructura de features
- `domain-modeler` — entidades DDD, value objects, repositorios (interfaces)
- `flutter-ui` — widgets, pantallas, providers Riverpod
- `test-writer` — tests unitarios, de widgets, integración
- `dart-expert` — código Dart idiomático, Dart 3 features
- `qa-engineer` — auditoría de calidad, validación de flujos, reportes QA
