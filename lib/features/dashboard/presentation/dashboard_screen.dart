import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/category_grid.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/tip_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync          = ref.watch(monthlySummaryProvider);
    final transactionsAsync     = ref.watch(recentTransactionsProvider);
    final categoriesAsync       = ref.watch(categoryExpensesProvider);
    final financialSummary = ref.watch(financialSummaryProvider);
    final currencyState = ref.watch(currencyNotifierProvider);

    final user      = Supabase.instance.client.auth.currentUser;
    final fullName  = (user?.userMetadata?['full_name'] as String?) ?? ref.tr('common.user');
    final firstName = fullName.split(RegExp(r'\s+')).first;
    final initials  = _initials(fullName);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar flotante ─────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_greeting(ref)}, $firstName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                ),
                Text(
                  _monthYear(ref),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF8892B0)
                            : const Color(0xFF9CA3AF),
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () => context.push('/notifications'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 2),
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: _UserAvatar(initials: initials),
                ),
              ),
            ],
          ),

          // ── Contenido principal ─────────────
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverList.list(
              children: [
                // Balance card
                BalanceCard(
                  income:    summaryAsync.valueOrNull?['income'],
                  expense:   summaryAsync.valueOrNull?['expense'],
                  available: financialSummary?.available,
                  saved:     financialSummary?.saved,
                  currency:  currencyState.baseCurrency,
                ),
                const SizedBox(height: 12),

                // Mini-cards de cuentas (silent fail si vacío o error)
                const _AccountMiniCardsRow(),
                const SizedBox(height: 8),

                // Tip IA
                const TipBanner(),
                const SizedBox(height: 22),

                // Sección Categorías
                _SectionHeader(
                  title: ref.tr('dashboard.categories'),
                  subtitle: ref.tr('dashboard.this_month'),
                ),
                const SizedBox(height: 10),
                CategoryGrid(
                  expenses: categoriesAsync.valueOrNull,
                  currency: currencyState.baseCurrency,
                ),
                const SizedBox(height: 22),

                // Sección Recientes
                _SectionHeader(
                  title: ref.tr('dashboard.recent'),
                  actionLabel: ref.tr('dashboard.view_all'),
                  onAction: () => context.push('/transactions'),
                ),
                const SizedBox(height: 6),
                RecentTransactionsList(
                  transactions: transactionsAsync.valueOrNull,
                ),
              ],
            ),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: const Color(0xFF2F7155),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          ref.tr('dashboard.add'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────

  static String _greeting(WidgetRef ref) {
    final h = DateTime.now().hour;
    if (h < 12) return ref.tr('dashboard.greeting_morning');
    if (h < 19) return ref.tr('dashboard.greeting_afternoon');
    return ref.tr('dashboard.greeting_night');
  }

  static String _monthYear(WidgetRef ref) {
    final now = DateTime.now();
    final monthKeys = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final monthName = ref.tr('months.${monthKeys[now.month - 1]}');
    return '$monthName ${now.year}';
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final p = parts[0];
    return p.substring(0, p.length.clamp(0, 2)).toUpperCase();
  }
}

// ─────────────────────────────────────────────
//  Avatar circular con iniciales + gradiente
// ─────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String initials;
  const _UserAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F7155), Color(0xFF6BC99D)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Mini-cards de cuentas (scroll horizontal)
// ─────────────────────────────────────────────

class _AccountMiniCardsRow extends ConsumerWidget {
  const _AccountMiniCardsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    return accountsAsync.maybeWhen(
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = accounts[i];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final cs = Theme.of(context).colorScheme;
              final c = Theme.of(context).extension<FinPaColors>()!;
              final isCredit = a.type == AccountType.credit;
              return GestureDetector(
                onTap: () => context.push('/accounts'),
                child: Container(
                  width: 148,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(a.type.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              a.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: c.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        CurrencyFormatter.format(a.balance, currency: a.currency),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCredit ? c.expense : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────
//  Encabezado de sección
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textMuted   = isDark ? const Color(0xFF8892B0) : const Color(0xFF9CA3AF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F7155),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

