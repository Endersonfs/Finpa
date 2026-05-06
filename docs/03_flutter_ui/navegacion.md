# Navegación con GoRouter en Finpa

---

## Estructura de rutas

```
/splash             → SplashScreen (sin shell)
/onboarding         → OnboardingScreen (sin shell)
/auth/login         → LoginScreen (sin shell)
/auth/register      → RegisterScreen (sin shell)
/auth/forgot        → ForgotPasswordScreen (sin shell)
/lock               → LockScreen (sin shell)

StatefulShellRoute (MainShell — NavigationBar con 5 tabs)
  /dashboard        → DashboardScreen
  /transactions     → TransactionsScreen
    /transactions/add       → AddTransactionScreen
    /transactions/:id       → TransactionDetailScreen
  /budget           → BudgetScreen
    /budget/add             → AddBudgetScreen
    /budget/:id             → BudgetDetailScreen
  /goals            → GoalsScreen
    /goals/add              → AddGoalScreen
    /goals/:id              → GoalDetailScreen
  /chat             → ChatScreen

/accounts           → AccountsScreen (sin shell, pantalla secundaria)
  /accounts/add-bank
  /accounts/transfer
  /accounts/:id
/reports            → ReportsScreen
/education          → EducationScreen
  /education/:id
/profile            → ProfileScreen
/settings           → SettingsScreen
  /settings/appearance
/notifications      → NotificationsScreen
/security           → SecurityScreen
/currency-selector  → CurrencySelectorScreen
```

---

## Cómo navegar

```dart
// Navegar a una ruta
context.go('/dashboard');
context.go('/transactions');

// Navegar con parámetros de ruta
context.go('/transactions/${transaction.id}');
context.go('/goals/${goal.id}');

// Push (agrega al stack — tiene botón de volver)
context.push('/transactions/add');
context.push('/budget/add');

// Pop (volver atrás)
context.pop();

// Pop con resultado
context.pop(true); // el screen anterior recibe el valor

// Navegar y reemplazar el stack (sin posibilidad de volver)
context.goNamed('dashboard');
```

---

## Recibir parámetros de ruta

```dart
// Definición en app_router.dart
GoRoute(
  path: ':id',
  builder: (_, state) => TransactionDetailScreen(
    id: state.pathParameters['id']!,
  ),
),

// En el screen
class TransactionDetailScreen extends StatelessWidget {
  final String id;
  const TransactionDetailScreen({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    // Cargar la transacción con el id
    ...
  }
}
```

---

## Guards de navegación (redirect)

El router tiene tres capas de protección en la función `redirect`:

```dart
redirect: (context, state) {
  final user = Supabase.instance.client.auth.currentUser;
  final onboardingDone = prefs.getBool('finpa_onboarding_done') ?? false;
  final location = state.matchedLocation;

  // Capa 1: Onboarding (primer uso)
  if (user == null && !onboardingDone) return '/onboarding';

  // Capa 2: Auth (usuario no logueado)
  if (user == null && !location.startsWith('/auth')) return '/auth/login';
  if (user != null && location.startsWith('/auth')) return '/dashboard';

  // Capa 3: Lock de sesión (biometría)
  if (user != null) {
    final sessionState = container.read(sessionProvider);
    if (sessionState.isLocked && location != '/lock') return '/lock';
    if (!sessionState.isLocked && location == '/lock') return '/dashboard';
  }

  return null; // sin redirect — continúa normal
}
```

El router escucha cambios de auth de Supabase via `_RouterRefreshStream` y re-evalúa el redirect automáticamente.

---

## Rutas con shell vs sin shell

**Con shell** (dentro del `StatefulShellRoute`): tienen la barra de navegación inferior con los 5 tabs. El estado de cada tab se preserva al cambiar de tab.

**Sin shell**: no tienen barra de navegación. Se accede con `context.push()` y se vuelve con `context.pop()`.

```dart
// Pantalla secundaria — push para mantener botón de volver
onTap: () => context.push('/accounts'),

// Tab principal — go para cambiar de tab sin apilar
onTap: () => context.go('/dashboard'),
```

---

## Agregar una nueva ruta

1. Crear el screen en `lib/features/{feature}/presentation/`
2. Importarlo en `router/app_router.dart`
3. Agregar el `GoRoute` en la sección correspondiente:
   - Si tiene NavigationBar: dentro del `StatefulShellBranch`
   - Si es pantalla secundaria: en la sección "sin shell"

```dart
// En app_router.dart
GoRoute(
  path: '/mi-nueva-pantalla',
  builder: (_, __) => const MiNuevaPantalla(),
),

// Con parámetro
GoRoute(
  path: '/mi-feature/:id',
  builder: (_, state) => MiFeatureDetailScreen(
    id: state.pathParameters['id']!,
  ),
),
```
