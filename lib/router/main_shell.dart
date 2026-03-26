import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,                 activeIcon: Icons.home_rounded,                   label: 'Inicio'),
    _TabItem(icon: Icons.receipt_long_outlined,         activeIcon: Icons.receipt_long_rounded,           label: 'Movim.'),
    _TabItem(icon: Icons.pie_chart_outline,             activeIcon: Icons.pie_chart_rounded,              label: 'Presup.'),
    _TabItem(icon: Icons.flag_outlined,                 activeIcon: Icons.flag_rounded,                   label: 'Metas'),
    _TabItem(icon: Icons.smart_toy_outlined,            activeIcon: Icons.smart_toy_rounded,              label: 'FinPa IA'),
    _TabItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Cuentas'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Volver al initial location al retap del tab activo
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores según tema
    const selectedColor   = Color(0xFF3B5BDB);
    final unselectedColor = isDark ? const Color(0xFF4A5580) : const Color(0xFF9CA3AF);
    final bgColor         = isDark ? const Color(0xFF060810) : const Color(0xFFFFFFFF);
    final borderColor     = isDark ? const Color(0xFF1E2535) : const Color(0xFFE2E6F0);
    final indicatorColor  = isDark
        ? const Color(0xFF3B5BDB).withOpacity(0.20)
        : const Color(0xFF3B5BDB).withOpacity(0.12);

    return Scaffold(
      body: navigationShell,
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
                fontSize: 10,
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
            selectedIndex: navigationShell.currentIndex,
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
