# Guía de Ejecución de Tareas

Cómo ejecutar las mejoras listadas en `/tasks.md`.

---

## Orden recomendado

Las tareas tienen dependencias entre sí. Este orden minimiza el retrabajo:

```
1. Tests base (tarea 2)           → da seguridad para todo lo demás
2. AppException (tarea 5.1-5.2)   → base que usan los demás fixes
3. Traducciones (tarea 3)         → mecánico, sin riesgo
4. Dark Mode (tarea 4)            → mecánico, sin riesgo
5. Sync robustez (tarea 1)        → con tests ya existentes
6. Providers refactor (tarea 6)   → con tests protegiendo
7. IA mejoras (tarea 7)           → independiente
8. UX estados (tarea 8)           → independiente
9. Performance (tarea 11)         → al final, cuando todo estabiliza
10. Lints y limpieza (tarea 10)   → al final
```

---

## Comandos de verificación

Usar después de cada grupo de cambios:

```bash
# Verificar que no hay errores de compilación ni warnings
flutter analyze

# Correr todos los tests
flutter test

# Regenerar código tras cambios en @HiveType o @Riverpod
dart run build_runner build --delete-conflicting-outputs

# Buscar strings hardcodeados que deberían estar en traducciones
grep -rn '"[A-Z][a-z]' lib/features --include="*.dart"

# Buscar colores hardcodeados que rompen dark mode
grep -rn "Color(0x" lib/features --include="*.dart"

# Buscar usos de withOpacity (deprecado)
grep -rn "withOpacity" lib/ --include="*.dart"
```

---

## Skills de Claude disponibles

| Tarea | Skill |
|-------|-------|
| Nueva feature completa | `/add-feature` |
| Crear/mejorar pantalla | `/flutter-screen` |
| Revisar calidad Dart | `/dart-review` |
| Escribir tests | `/test-writer` |
| Crear tabla Supabase | `/supabase-table` |
| Crear PR | `/pull-request` |

---

## Flujo por tipo de tarea

### Para fixes mecánicos (traducciones, dark mode)
```
1. Identificar el archivo con grep
2. Pedir a Claude: "Mueve los hardcoded strings de X a ref.tr()"
3. Verificar que los JSON de traducciones se actualizaron
4. flutter analyze
```

### Para cambios estructurales (nueva clase base, refactor)
```
1. Discutir el diseño primero (preguntar sin implementar)
2. Implementar la base primero (AppException, CrudNotifier)
3. Migrar uno por uno, corriendo tests entre cada migración
4. flutter analyze + flutter test al final
```

### Para nuevas features
```
1. Usar /add-feature para estructura inicial
2. Definir entity en domain
3. Implementar repository en data
4. Crear providers
5. Crear la UI
6. Agregar ruta en app_router.dart
7. Usar /test-writer para los tests
```

---

## Checklist antes de commit

- [ ] `flutter analyze` sin warnings
- [ ] `flutter test` todos pasan
- [ ] Si agregué `@HiveType`: nuevo typeId en la tabla de `hive_local.md` y en `HiveService`
- [ ] Si agregué strings nuevos: están en `es.json` y `en.json`
- [ ] Si modifiqué UI: probé en light mode y dark mode
- [ ] Si modifiqué `@Riverpod` o `@HiveType`: corrí `build_runner`

---

## Referencia de archivos clave

| Qué modificar | Dónde |
|---------------|-------|
| Agregar ruta | `lib/router/app_router.dart` |
| Registrar Hive adapter | `lib/core/local_storage/hive_service.dart` |
| Agregar traducción | `assets/translations/es.json` y `en.json` |
| Colores del tema | `lib/core/theme/app_theme.dart` |
| Configuración del router | `lib/router/app_router.dart` |
| Variables de entorno | `.env` (no commitear) |
