import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/biometric_provider.dart';
import '../../auth/providers/session_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../goals/providers/goals_provider.dart';
import '../../education/providers/education_provider.dart';

import '../../../core/providers/language_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final themeMode = ref.watch(themeProvider);
    final currencyState = ref.watch(currencyNotifierProvider);

    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? ref.tr('common.user');
    final email = user?.email ?? '';
    final initials = _getInitials(fullName);

    final txnCount =
        ref.watch(transactionsProvider).valueOrNull?.length ?? 0;
    final activeGoals = ref
            .watch(goalsProvider)
            .valueOrNull
            ?.where((g) => !g.isCompleted)
            .length ??
        0;
    final modules = ref.watch(modulesProvider).valueOrNull ?? [];
    final completedLessons =
        modules.fold<int>(0, (sum, m) => sum + m.completedCount);
    final totalLessons = modules.fold<int>(0, (sum, m) => sum + m.totalCount);

    final themeLabel = switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => ref.tr('settings.follow_system'),
    };

    final currencyLabel = '${currencyState.baseCurrency.symbol} · ${currencyState.baseCurrency.code}';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: scaffoldBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              ref.tr('settings.profile'),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: textPrimary,
                ),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverList.list(
            children: [
              // ── Header de perfil ──────────────────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF2F7155), Color(0xFF6BC99D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D1227)
                              : const Color(0xFFEEF2FF),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFC7D2FE),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ref.tr('settings.free_plan'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                      label: ref.tr('transactions.title'),
                      value: txnCount.toString(),
                      surface: surface,
                      border: c.border,
                      textPrimary: textPrimary,
                      muted: c.muted,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: ref.tr('goals.active_goals'),
                      value: activeGoals.toString(),
                      surface: surface,
                      border: c.border,
                      textPrimary: textPrimary,
                      muted: c.muted,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: ref.tr('education.modules'),
                      value: '$completedLessons/$totalLessons',
                      surface: surface,
                      border: c.border,
                      textPrimary: textPrimary,
                      muted: c.muted,
                    ),
                  ],
                ),
              ),

              // ── Sección "Mi cuenta" ───────────────────────────────────
              _SectionTitle(
                title: ref.tr('settings.profile').toUpperCase(),
                textSecondary: textSecondary,
              ),
              _ProfileTile(
                icon: Icons.person_outline_rounded,
                label: ref.tr('settings.manage_profile'),
                iconBg: const Color(0xFF2F7155),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ref.tr('common.soon'))),
                ),
              ),
              _ProfileTile(
                icon: Icons.account_balance_wallet_outlined,
                label: ref.tr('accounts.title'),
                iconBg: const Color(0xFF059669),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                onTap: () => context.push('/accounts'),
              ),
              _ProfileTile(
                icon: Icons.language_rounded,
                label: ref.tr('settings.main_currency'),
                iconBg: const Color(0xFF059669),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
                  ],
                ),
                onTap: () => context.push('/currency-selector'),
              ),
              _ProfileTile(
                icon: Icons.notifications_outlined,
                label: ref.tr('settings.notifications'),
                iconBg: const Color(0xFF7C3AED),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                onTap: () => context.push('/notifications'),
              ),
              _ProfileTile(
                icon: Icons.bar_chart_rounded,
                label: ref.tr('reports.title'),
                iconBg: const Color(0xFF0891B2),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                onTap: () => context.push('/reports'),
              ),

              // ── Sección "Preferencias" ────────────────────────────────
              _SectionTitle(
                title: ref.tr('settings.preferences').toUpperCase(),
                textSecondary: textSecondary,
              ),
              _ProfileTile(
                icon: Icons.palette_outlined,
                label: ref.tr('settings.appearance'),
                iconBg: const Color(0xFFD97706),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      themeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
                  ],
                ),
                onTap: () => context.push('/settings/appearance'),
              ),
              _ProfileTile(
                icon: Icons.lock_outline_rounded,
                label: ref.tr('settings.security'),
                iconBg: const Color(0xFFDC2626),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                onTap: () => context.push('/security'),
              ),
              _ProfileTile(
                icon: Icons.share_outlined,
                label: ref.tr('settings.share_finpa'),
                iconBg: const Color(0xFF6366F1),
                surface: surface,
                border: c.border,
                textPrimary: textPrimary,
                muted: c.muted,
                onTap: () {},
              ),

              // ── Zona peligrosa — Cerrar sesión ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: GestureDetector(
                  onTap: () => _confirmSignOut(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A0A0A)
                          : const Color(0xFFFEF2F2),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF5C1A1A)
                            : const Color(0xFFFECACA),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ref.tr('settings.logout'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final biometric = ref.read(biometricProvider);

    // Si la biometría está activa, bloquear la sesión en lugar de desconectar.
    // El usuario podrá desconectarse completamente desde la pantalla de bloqueo.
    if (biometric.isEnabled) {
      ref.read(sessionProvider.notifier).lock();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(ref.tr('settings.logout_confirm_title')),
        content: Text(ref.tr('settings.logout_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ref.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              ref.tr('settings.logout'),
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }
}

// ── _StatCard ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color muted;

  const _StatCard({
    required this.label,
    required this.value,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── _SectionTitle ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color textSecondary;

  const _SectionTitle({required this.title, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── _ProfileTile ───────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color muted;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.muted,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
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
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        trailing:
            trailing ?? Icon(Icons.chevron_right_rounded, color: muted, size: 20),
        onTap: onTap,
      ),
    );
  }
}

