# Finpa — Lista de Tareas de Mejora

Organizado por área y prioridad. Cada subtarea es lo suficientemente pequeña para completarse en una sesión.

---

## 🔴 Crítico

### 1. Sincronización Offline Robusta (`sync_service.dart`)
- [ ] 1.1 Reemplazar `catch (_) {}` vacíos con logging de errores en `_uploadPendingTransactions`, `_uploadPendingAccounts`, `_uploadPendingBudgets`, `_uploadPendingGoals`
- [ ] 1.2 Agregar contador de reintentos (`retryCount`) por registro fallido para no reintentar infinitamente
- [ ] 1.3 Corregir la lógica inconsistente en `_downloadNewGoals` — unificar con el mismo patrón que transactions/accounts/budgets
- [ ] 1.4 Exponer un `syncStatusProvider` (Riverpod) que indique si hay registros pendientes de sincronizar
- [ ] 1.5 Mostrar un indicador visual (ícono pequeño) en el shell cuando hay datos pendientes de sync

### 2. Cobertura de Tests
- [ ] 2.1 Test unitario: `TransactionRepository.fetchAll` — verifica filtro por mes/año
- [ ] 2.2 Test unitario: `TransactionRepository.add` — verifica que actualiza saldo de cuenta y presupuesto
- [ ] 2.3 Test unitario: `TransactionRepository.delete` — verifica soft-delete y reversión de saldo
- [ ] 2.4 Test unitario: `SyncService.syncAll` — mock de Supabase, verifica que sube pendientes y descarga nuevos
- [ ] 2.5 Test unitario: `LanguageState.translate` — verifica dot-notation y fallback a key
- [ ] 2.6 Test de widget: `DashboardScreen` — verifica que muestra shimmer mientras carga y datos cuando completa
- [ ] 2.7 Test de widget: `AddTransactionScreen` — verifica validación de formulario
- [ ] 2.8 Test de widget: `LoginScreen` — verifica estados de error de Supabase

---

## 🟠 Alto

### 3. Hardcoded Strings → Traducciones
- [ ] 3.1 `login_screen.dart` — mover a claves: `auth.welcome`, `auth.or_continue_with`, `auth.continue_google`, `auth.login_face_id`, `auth.login_fingerprint`
- [ ] 3.2 `register_screen.dart` — mover a claves: `auth.register_subtitle`, `auth.full_name`, `auth.confirm_password`, `auth.password_weak`, `auth.password_medium`, `auth.password_strong`, `auth.passwords_no_match`, `auth.terms_accept`
- [ ] 3.3 `education_screen.dart` — mover a claves: `education.your_progress`, `education.completed_suffix`, `education.status_completed`, `education.status_in_progress`, `education.status_locked`
- [ ] 3.4 `settings_screen.dart` — mover nombres de idioma a claves: `settings.lang_es`, `settings.lang_en`
- [ ] 3.5 `chat_screen.dart` — mover el string hardcoded `'Dame consejos de ahorro'` a clave `chat.tip_suggestion`
- [ ] 3.6 Agregar todas las claves nuevas a `assets/translations/es.json` y `assets/translations/en.json`
- [ ] 3.7 Auditar el resto de screens con `grep -r '"[A-Z]' lib/features` y completar las claves faltantes

### 4. Dark Mode — Colores Hardcoded
- [ ] 4.1 `login_screen.dart` — reemplazar `Color(0xFFF5F6FA)` con `Theme.of(context).scaffoldBackgroundColor`
- [ ] 4.2 `register_screen.dart` — mismo fix que 4.1
- [ ] 4.3 `forgot_password_screen.dart` — revisar y aplicar mismo fix si aplica
- [ ] 4.4 `onboarding_screen.dart` — verificar que gradientes y textos usen colores del tema
- [ ] 4.5 Buscar todos los `Color(0xFF...)` hardcodeados en screens con `grep -rn "Color(0x" lib/features` y reemplazar con `FinPaColors` o `Theme.of(context).colorScheme`

### 5. Manejo de Errores Consistente
- [ ] 5.1 Crear `lib/core/errors/app_exception.dart` — clase base con `message`, `code` y factory constructors para tipos comunes (network, auth, notFound)
- [ ] 5.2 Crear `lib/core/widgets/error_snack_bar.dart` — helper estático `ErrorSnackBar.show(context, message)` con estilo consistente
- [ ] 5.3 Reemplazar los `throw Exception('...')` en repositorios con `AppException`
- [ ] 5.4 Unificar el manejo de errores en `AuthRepository` — un solo punto de conversión de `AuthException` de Supabase a `AppException`
- [ ] 5.5 En `ai_repository.dart` — propagar el error correctamente al provider en lugar de silenciarlo en `generateAutoTip()`

---

## 🟡 Medio

### 6. Refactor de Providers Duplicados
- [ ] 6.1 Analizar el patrón común en `budget_provider`, `goals_provider`, `transactions_provider` y `accounts_provider`
- [ ] 6.2 Crear mixin o clase base `CrudNotifier<T>` con métodos `add`, `remove`, `refresh` genéricos
- [ ] 6.3 Migrar `BudgetNotifier` al nuevo patrón base
- [ ] 6.4 Migrar `GoalsNotifier` al nuevo patrón base
- [ ] 6.5 Migrar `TransactionsNotifier` al nuevo patrón base

### 7. Integración de IA Mejorada
- [ ] 7.1 Actualizar el modelo en `ai_repository.dart` de `claude-3-5-sonnet-20240620` a `claude-sonnet-4-6` (modelo actual)
- [ ] 7.2 Agregar validación al iniciar la app: si `ANTHROPIC_API_KEY` está vacía, deshabilitar el tab de chat con mensaje explicativo
- [ ] 7.3 Implementar estados de error diferenciados en `ChatScreen`: error de red vs. error de API vs. respuesta vacía
- [ ] 7.4 Agregar límite de longitud al historial del chat en `chatProvider` para evitar tokens excesivos (máx. 20 mensajes)
- [ ] 7.5 Persistir el historial del chat en Hive para que sobreviva reinicios de app

### 8. UX — Estados de Carga y Vacío
- [ ] 8.1 `ReportsScreen` — agregar skeleton loader mientras cargan los datos de gráficas
- [ ] 8.2 `GoalsScreen` — mejorar el estado vacío con ilustración y CTA para crear primera meta
- [ ] 8.3 `BudgetScreen` — mejorar el estado vacío con CTA para crear primer presupuesto
- [ ] 8.4 `AccountsScreen` — agregar estado vacío cuando no hay cuentas registradas
- [ ] 8.5 `TransactionsScreen` — agregar pull-to-refresh que dispare `syncAll()` manualmente

### 9. Seguridad y Auth
- [ ] 9.1 `lock_screen.dart` — agregar timeout automático de sesión configurable (en `SecurityScreen`)
- [ ] 9.2 Agregar validación de fortaleza de contraseña también en el backend (regla en Supabase Auth)
- [ ] 9.3 Verificar que `flutter_secure_storage` se usa para tokens sensibles y no `shared_preferences`
- [ ] 9.4 Agregar opción de "cerrar todas las sesiones" en `SecurityScreen`

---

## 🟢 Bajo

### 10. Calidad de Código
- [ ] 10.1 Habilitar lints adicionales en `analysis_options.yaml`: `prefer_single_quotes`, `avoid_print`, `require_trailing_commas`
- [ ] 10.2 Reemplazar todos los `print()` restantes con un logger estructurado (o eliminarlos)
- [ ] 10.3 Marcar `appRouterProvider` como eliminado (ya tiene `@Deprecated`) y remover usos
- [ ] 10.4 Revisar que todos los `HiveObject` con `@HiveType` tengan sus `typeId` documentados en `hive_service.dart`
- [ ] 10.5 Agregar `const` constructors donde sea posible (correr `flutter analyze` para detectarlos)

### 11. Performance
- [ ] 11.1 Revisar que los `FutureProvider` en dashboard no recalculen en cada rebuild — usar `keepAlive` donde aplique
- [ ] 11.2 `category_grid.dart` — verificar que los íconos de categorías no se reconstruyen innecesariamente (usar `const`)
- [ ] 11.3 Implementar paginación en `TransactionsScreen` para no cargar todas las transacciones de Hive en memoria
- [ ] 11.4 Lazy-load el tab de educación — no cargar lecciones hasta que el usuario navegue a esa pantalla

### 12. Documentación del Proyecto
- [ ] 12.1 Agregar comentario de cabecera en `hive_service.dart` con la tabla de TypeIds actualizada
- [ ] 12.2 Documentar el flujo completo de sync en un diagrama ASCII en `sync_service.dart`
- [ ] 12.3 Agregar instrucciones de configuración del `.env` en el README (variables requeridas)

---

## 📊 Resumen

| Área | Tareas | Subtareas |
|------|--------|-----------|
| Sync Offline | 1 | 5 |
| Tests | 1 | 8 |
| Traducciones | 1 | 7 |
| Dark Mode | 1 | 5 |
| Manejo de Errores | 1 | 5 |
| Providers Duplicados | 1 | 5 |
| Integración IA | 1 | 5 |
| UX Estados | 1 | 5 |
| Seguridad | 1 | 4 |
| Calidad de Código | 1 | 5 |
| Performance | 1 | 4 |
| Documentación | 1 | 3 |
| **Total** | **12** | **61** |
