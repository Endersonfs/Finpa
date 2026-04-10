import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/biometric_provider.dart' show biometricProvider, BiometricState, BiometricNotEnrolledException;
import '../../auth/providers/session_provider.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final surface = theme.colorScheme.surface;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    final biometric = ref.watch(biometricProvider);
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Seguridad',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        leading: BackButton(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // ── Sección: Acceso biométrico ───────────────────────────────
          _SectionHeader(
            title: 'ACCESO BIOMÉTRICO',
            textSecondary: textSecondary,
          ),
          _Card(
            isDark: isDark,
            surface: surface,
            border: c.border,
            child: Column(
              children: [
                SwitchListTile(
                  value: biometric.isEnabled,
                  onChanged: biometric.isAvailable
                      ? (value) => _toggleBiometric(
                          context, ref, biometric, value)
                      : null,
                  title: Text(
                    'Huella / Face ID',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    biometric.isAvailable
                        ? biometric.hasFaceId
                            ? 'Desbloquea con Face ID'
                            : 'Desbloquea con tu huella dactilar'
                        : 'Tu dispositivo no soporta biometría',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: biometric.isAvailable
                          ? const Color(0xFF2F7155)
                          : c.muted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      biometric.hasFaceId
                          ? Icons.face_rounded
                          : Icons.fingerprint_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  activeThumbColor: const Color(0xFF2F7155),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Sección: Tiempo de sesión ────────────────────────────────
          _SectionHeader(
            title: 'TIEMPO DE SESION',
            textSecondary: textSecondary,
          ),
          _Card(
            isDark: isDark,
            surface: surface,
            border: c.border,
            child: Column(
              children: [
                // Switch principal
                SwitchListTile(
                  value: session.isSessionTimeoutEnabled,
                  onChanged: (value) => ref
                      .read(sessionProvider.notifier)
                      .setSessionTimeoutEnabled(value),
                  title: Text(
                    'Cerrar sesión automáticamente',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Bloquea la app tras periodo de inactividad',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  activeThumbColor: const Color(0xFF2F7155),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),

                // Opciones de tiempo — solo si está habilitado
                if (session.isSessionTimeoutEnabled) ...[
                  Divider(color: c.border, height: 1),
                  _TimeoutTile(
                    icon: Icons.touch_app_outlined,
                    iconBg: const Color(0xFF0891B2),
                    title: 'Inactividad',
                    currentMinutes: session.inactivityTimeoutMinutes,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    muted: c.muted,
                    border: c.border,
                    onChanged: (minutes) => ref
                        .read(sessionProvider.notifier)
                        .setInactivityTimeout(minutes),
                  ),
                  Divider(color: c.border, height: 1),
                  _TimeoutTile(
                    icon: Icons.phonelink_lock_outlined,
                    iconBg: const Color(0xFF059669),
                    title: 'Tiempo en segundo plano',
                    currentMinutes: session.backgroundTimeoutMinutes,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    muted: c.muted,
                    border: c.border,
                    onChanged: (minutes) => ref
                        .read(sessionProvider.notifier)
                        .setBackgroundTimeout(minutes),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    BiometricState biometric,
    bool enable,
  ) async {
    if (enable) {
      bool confirmed = false;
      String? errorMessage;

      try {
        confirmed = await ref.read(biometricProvider.notifier).authenticate();
        if (!confirmed) errorMessage = 'No se pudo verificar tu identidad';
      } on BiometricNotEnrolledException {
        errorMessage =
            'No tienes huella ni Face ID registrado en el dispositivo';
      }

      if (!confirmed) {
        if (context.mounted && errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        }
        return;
      }
    }
    await ref.read(biometricProvider.notifier).enableBiometric(enable);
  }
}

// ── Componentes internos ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textSecondary;

  const _SectionHeader({
    required this.title,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color surface;
  final Color border;

  const _Card({
    required this.child,
    required this.isDark,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _TimeoutTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final int currentMinutes;
  final bool isDark;
  final Color textPrimary;
  final Color muted;
  final Color border;
  final ValueChanged<int> onChanged;

  static const _options = [1, 2, 5, 10, 15, 30];

  const _TimeoutTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.currentMinutes,
    required this.isDark,
    required this.textPrimary,
    required this.muted,
    required this.border,
    required this.onChanged,
  });

  String _label(int minutes) {
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _options.contains(currentMinutes)
              ? currentMinutes
              : _options.first,
          items: _options
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      _label(m),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          dropdownColor: isDark
              ? const Color(0xFF141928)
              : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: textPrimary,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: muted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

