# Documentación Finpa

Carpeta de referencia y estudio para el proyecto. Cada sección explica un concepto con ejemplos reales del código.

## Índice

```
docs/
  01_arquitectura/
    clean_architecture.md     → Capas, dependencias, reglas
    offline_first.md          → Hive + Supabase sync pattern
    ddd_bounded_contexts.md   → Features como bounded contexts
  02_riverpod/
    tipos_de_providers.md     → FutureProvider, StreamProvider, Notifier
    patrones_comunes.md       → invalidate, autoDispose, keepAlive
  03_flutter_ui/
    design_system.md          → FinPaColors, AppTheme, reglas visuales
    shimmer_loading.md        → Skeleton loaders, ShimmerBox
    navegacion.md             → GoRouter, guards, rutas con shell
  04_backend/
    supabase_auth.md          → Auth flow, OAuth, biometría
    hive_local.md             → HiveObject, TypeIds, boxes
    sync_pattern.md           → Cómo funciona la sincronización offline
  05_dart/
    dart3_features.md         → Patterns, records, sealed classes
    null_safety.md            → Patrones null-safe en este proyecto
  06_testing/
    guia_tests.md             → Cómo testear providers, repos, widgets
    ejemplos.md               → Tests reales con mocktail
  07_tareas/
    tasks.md                  → (ver /tasks.md en raíz del proyecto)
    guia_ejecucion.md         → Cómo ejecutar las mejoras pendientes
    workflow_crear_pr.md      → Nomenclatura de branches, pasos y checklist para abrir PRs
```

## Cómo usar esta documentación

- Cada archivo tiene **concepto → por qué → código real del proyecto**
- Los ejemplos son del código existente, no inventados
- Cuando implementes algo nuevo, primero lee el doc del área correspondiente
