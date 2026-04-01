# Finpa - Contexto del Proyecto

## Qué es Finpa
Aplicación móvil financiera personal desarrollada en Flutter.
Plataformas: Android e iOS.

## Arquitectura: Clean Architecture + DDD

### Capas (de adentro hacia afuera)
```
Domain → Data → Presentation
```

1. **Domain** (núcleo, sin dependencias externas)
   - `entities/` — Objetos de negocio puros (igualdad manual por `id`)
   - `repositories/` — Interfaces (contratos) que define el dominio

2. **Data** (implementaciones)
   - `models/` — DTOs con `fromJson`/`toJson` + `toEntity()`
   - `datasources/` — Remote (Supabase) y Local (SharedPrefs/SecureStorage)
   - `repositories/` — Implementaciones de las interfaces del dominio

3. **Presentation** (UI)
   - `providers/` — Riverpod: `FutureProvider`, `NotifierProvider`, etc.
   - `screens/` — Pantallas completas (sufijo `Screen`)
   - `widgets/` — Componentes reutilizables

### Estructura de Carpetas
```
lib/
  core/
    theme/            # AppTheme, FinPaColors
    providers/        # theme_provider, shared_prefs
    widgets/          # Widgets compartidos
  features/
    {feature}/        # Bounded Context DDD
      data/
        models/
        datasources/
        repositories/
      domain/
        entities/
        repositories/  # interfaces
      presentation/
        providers/
        screens/
        widgets/
  router/
    app_router.dart
    main_shell.dart
  main.dart
```

## Reglas de Arquitectura (OBLIGATORIAS)

1. **Domain nunca importa de Data ni Presentation**
2. **Repositories en Domain son interfaces**, las implementaciones van en Data
3. **Entities usan `==` y `hashCode` manual por `id`** — no usar equatable
4. **Providers Riverpod manejan TODO el estado** — no lógica en widgets
5. **No instanciar clases directamente en widgets** — usar providers
6. **Modelos tienen `fromJson`/`toJson`** y método `toEntity()`
7. **Supabase solo accesible desde la capa DataSource**

## Convenciones de Nombres

- Entidades: `Transaction`, `Budget`, `Goal`
- Modelos: `TransactionModel`, `BudgetModel`
- Repositorios (interfaz): `TransactionRepository`
- Repositorios (impl): `TransactionRepositoryImpl`
- DataSources: `TransactionRemoteDataSource`
- Providers: `transactionsProvider`, `budgetProvider`

## Stack Técnico
- Flutter 3.x / Dart 3.10
- State: **flutter_riverpod ^2.5.1** (Riverpod — NO BLoC)
- Backend: supabase_flutter ^2.5.3
- Routing: go_router ^13.x
- Local: shared_preferences + flutter_secure_storage
- Fonts: google_fonts (Inter)
- Biometría: local_auth
- Tests: mocktail

## Patrones de UI

- Padding horizontal: **16px** siempre
- BorderRadius: 12px cards, 16px cards grandes
- Fuente: Inter via `google_fonts`
- Montos: `NumberFormat.currency(locale: 'es', symbol: 'Bs.', decimalDigits: 0)`
- **NO usar `withOpacity()`** — usar `withValues(alpha: x)` o `withAlpha(x)`
- Colores custom: `Theme.of(context).extension<FinPaColors>()!`
- Tema default: `ThemeMode.light`

## Sub-agentes disponibles
- `flutter-architect` — decisiones de arquitectura, estructura de features
- `domain-modeler` — entidades DDD, value objects, repositorios (interfaces)
- `flutter-ui` — widgets, pantallas, providers Riverpod
- `test-writer` — tests unitarios, de widgets, integración
- `dart-expert` — código Dart idiomático, Dart 3 features
- `qa-engineer` — auditoría de calidad, validación de flujos, reportes QA
