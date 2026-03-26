import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  bool _initialized = false;
  bool _budget = true;
  bool _tips = true;
  bool _reminder = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final themeMode = ref.watch(themeProvider);
    final prefs = ref.watch(sharedPrefsProvider);

    if (!_initialized) {
      _budget = prefs.getBool('finpa_notif_budget') ?? true;
      _tips = prefs.getBool('finpa_notif_tips') ?? true;
      _reminder = prefs.getBool('finpa_notif_reminder') ?? false;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apariencia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Sección "Tema de la app" ──────────────────────────────────
          Text(
            'Tema de la app',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 12),
          _ThemeOptionCard(
            title: 'Claro',
            subtitle: 'Fondo blanco, texto oscuro',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFD97706),
            isSelected: themeMode == ThemeMode.light,
            isDark: isDark,
            surface: surface,
            border: c.border,
            textPrimary: textPrimary,
            muted: c.muted,
            onTap: () => ref.read(themeProvider.notifier).setLight(),
          ),
          _ThemeOptionCard(
            title: 'Oscuro',
            subtitle: 'Fondo negro, texto claro',
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFF3B5BDB),
            isSelected: themeMode == ThemeMode.dark,
            isDark: isDark,
            surface: surface,
            border: c.border,
            textPrimary: textPrimary,
            muted: c.muted,
            onTap: () => ref.read(themeProvider.notifier).setDark(),
          ),
          _ThemeOptionCard(
            title: 'Sistema',
            subtitle: 'Sigue la configuración del móvil',
            icon: Icons.brightness_auto_rounded,
            iconColor: const Color(0xFF059669),
            isSelected: themeMode == ThemeMode.system,
            isDark: isDark,
            surface: surface,
            border: c.border,
            textPrimary: textPrimary,
            muted: c.muted,
            onTap: () => ref.read(themeProvider.notifier).setSystem(),
          ),

          // ── Sección "Notificaciones" ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text(
              'Notificaciones',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.muted,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                'Alertas de presupuesto',
                style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
              ),
              subtitle: Text(
                'Cuando llegues al 80% de un límite',
                style: GoogleFonts.inter(fontSize: 11, color: c.muted),
              ),
              value: _budget,
              activeThumbColor: const Color(0xFF3B5BDB),
              onChanged: (v) {
                setState(() => _budget = v);
                prefs.setBool('finpa_notif_budget', v);
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                'Tips semanales de FinPa IA',
                style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
              ),
              subtitle: Text(
                'Consejos personalizados cada semana',
                style: GoogleFonts.inter(fontSize: 11, color: c.muted),
              ),
              value: _tips,
              activeThumbColor: const Color(0xFF3B5BDB),
              onChanged: (v) {
                setState(() => _tips = v);
                prefs.setBool('finpa_notif_tips', v);
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                'Recordatorio diario',
                style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
              ),
              subtitle: Text(
                'Para registrar tus gastos del día',
                style: GoogleFonts.inter(fontSize: 11, color: c.muted),
              ),
              value: _reminder,
              activeThumbColor: const Color(0xFF3B5BDB),
              onChanged: (v) {
                setState(() => _reminder = v);
                prefs.setBool('finpa_notif_reminder', v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ThemeOptionCard ───────────────────────────────────────────────────────────

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color muted;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0D1227) : const Color(0xFFEEF2FF))
              : surface,
          border: Border.all(
            color: isSelected ? const Color(0xFF3B5BDB) : border,
            width: isSelected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF3B5BDB),
                size: 20,
              )
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
