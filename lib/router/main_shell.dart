import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/session_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,          label: 'Inicio'),
    _TabItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,  label: 'Movim.'),
    _TabItem(icon: Icons.pie_chart_outline,     activeIcon: Icons.pie_chart_rounded,     label: 'Presup.'),
    _TabItem(icon: Icons.flag_outlined,         activeIcon: Icons.flag_rounded,          label: 'Metas'),
    _TabItem(icon: Icons.smart_toy_outlined,    activeIcon: Icons.smart_toy_rounded,     label: 'FinPa IA'),
  ];

  DateTime? _backgroundedAt;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // ── Ciclo de vida de la app ────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = ref.read(sessionProvider);
    if (!session.isSessionTimeoutEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      if (backgroundedAt != null) {
        final elapsed = DateTime.now().difference(backgroundedAt);
        final threshold = Duration(
          minutes: ref.read(sessionProvider).backgroundTimeoutMinutes,
        );
        if (elapsed >= threshold) {
          _lock();
        }
      }
      _backgroundedAt = null;
    }
  }

  // ── Timer de inactividad (checar cada 30 s) ──

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      final session = ref.read(sessionProvider);
      if (!session.isSessionTimeoutEnabled) return;
      if (session.isLocked) return;

      final elapsed =
          DateTime.now().difference(session.lastActivityAt);
      final threshold =
          Duration(minutes: session.inactivityTimeoutMinutes);
      if (elapsed >= threshold) {
        _lock();
      }
    });
  }

  void _lock() {
    if (!mounted) return;
    ref.read(sessionProvider.notifier).lock();
    context.go('/lock');
  }

  void _onUserInteraction() {
    final session = ref.read(sessionProvider);
    if (!session.isSessionTimeoutEnabled) return;
    ref.read(sessionProvider.notifier).updateActivity();
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Vigilar cambios de isLocked para redirigir si el lock se dispara
    // desde fuera del timer (ej. lock manual).
    ref.listen(sessionProvider, (prev, next) {
      if (next.isLocked && !(prev?.isLocked ?? false)) {
        if (mounted) context.go('/lock');
      }
    });

    const selectedColor   = Color(0xFF2F7155);
    final unselectedColor = isDark ? const Color(0xFF4A5580) : const Color(0xFF9CA3AF);
    final bgColor         = isDark ? const Color(0xFF060810) : const Color(0xFFFFFFFF);
    final borderColor     = isDark ? const Color(0xFF1E2535) : const Color(0xFFE2E6F0);
    final indicatorColor  = isDark
        ? const Color(0xFF2F7155).withValues(alpha: 0.20)
        : const Color(0xFF2F7155).withValues(alpha: 0.12);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onUserInteraction,
      onPanUpdate: (_) => _onUserInteraction(),
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: bgColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: indicatorColor,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? selectedColor : unselectedColor,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  color: selected ? selectedColor : unselectedColor,
                  size: 22,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _tabs
                  .map((t) => NavigationDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.activeIcon),
                        label: t.label,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

