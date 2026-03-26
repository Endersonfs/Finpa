import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';

// Shell — 6 tabs
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/transactions/presentation/add_transaction_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/budget/presentation/add_budget_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/goals/presentation/add_goal_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/ai_chat/presentation/chat_screen.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/accounts/presentation/add_bank_account_screen.dart';
import '../features/accounts/presentation/transfer_screen.dart';

// Secundarias (sin shell)
import '../features/reports/presentation/reports_screen.dart';
import '../features/education/presentation/education_screen.dart';
import '../features/education/presentation/lesson_detail_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/appearance_screen.dart';
import '../features/settings/presentation/notifications_screen.dart';

import '../core/providers/theme_provider.dart';
import 'main_shell.dart';

// ─────────────────────────────────────────────
//  Listenable que dispara refresh de GoRouter
//  cada vez que cambia el estado de auth
// ─────────────────────────────────────────────
class _RouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _RouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
//  Provider principal del router
// ─────────────────────────────────────────────
bool get _supabaseReady {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(sharedPrefsProvider);

  final refreshStream = _RouterRefreshStream(
    _supabaseReady
        ? Supabase.instance.client.auth.onAuthStateChange
        : const Stream.empty(),
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshStream,
    debugLogDiagnostics: false,

    // ── Redirect global ────────────────────────
    redirect: (context, state) {
      final user = _supabaseReady
          ? Supabase.instance.client.auth.currentUser
          : null;
      final onboardingDone  = prefs.getBool('finpa_onboarding_done') ?? false;
      final location        = state.matchedLocation;

      final isSplash     = location == '/splash';
      final isOnboarding = location == '/onboarding';
      final isAuth       = location.startsWith('/auth');

      // Splash y onboarding siempre se muestran tal cual
      if (isSplash || isOnboarding) return null;

      // Sin sesión y sin onboarding → onboarding
      if (user == null && !onboardingDone) return '/onboarding';

      // Sin sesión fuera de auth → login
      if (user == null && !isAuth) return '/auth/login';

      // Con sesión en pantallas de auth → dashboard
      if (user != null && isAuth) return '/dashboard';

      return null;
    },

    routes: [
      // ── Rutas sin shell — flujo inicial ───────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Shell principal con 5 tabs ─────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          // Tab 0 — Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1 — Transacciones
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, __) => const TransactionsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddTransactionScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => TransactionDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 — Presupuesto
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budget',
                builder: (_, __) => const BudgetScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddBudgetScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3 — Metas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (_, __) => const GoalsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddGoalScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => GoalDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 4 — FinPa IA
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (_, __) => const ChatScreen(),
              ),
            ],
          ),

          // Tab 5 — Cuentas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accounts',
                builder: (_, __) => const AccountsScreen(),
                routes: [
                  GoRoute(
                    path: 'add-bank',
                    builder: (_, __) => const AddBankAccountScreen(),
                  ),
                  GoRoute(
                    path: 'transfer',
                    builder: (_, __) => const TransferScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Rutas sin shell — secundarias ─────────
      GoRoute(
        path: '/reports',
        builder: (_, __) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/education',
        builder: (_, __) => const EducationScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => LessonDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (_, __) => const AppearanceScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Ruta no encontrada\n${state.uri}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  // Limpiar recursos cuando el provider se destruya
  ref.onDispose(() {
    refreshStream.dispose();
    router.dispose();
  });

  return router;
});

// Mantener compatibilidad con código anterior que use appRouterProvider
@Deprecated('Usar routerProvider')
final appRouterProvider = routerProvider;
