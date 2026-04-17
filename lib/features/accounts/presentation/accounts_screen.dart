import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/account_model.dart';
import '../providers/accounts_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _f(double v, {AccountModel? account}) => 
    CurrencyFormatter.format(v, currency: account?.currency);

// ─────────────────────────────────────────────────────────────────────────────
//  AccountsScreen
// ─────────────────────────────────────────────────────────────────────────────

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref.tr('accounts.title'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => context.push('/accounts/transfer'),
            tooltip: ref.tr('accounts.transfer'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/accounts/add-bank'),
            tooltip: ref.tr('accounts.add_account'),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => _AccountsSkeleton(c: c, cs: cs),
        error: (e, _) => _ErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(accountsStreamProvider),
          c: c,
        ),
        data: (accounts) => _AccountsBody(
          accounts: accounts,
          c: c,
          cs: cs,
          isDark: isDark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Body
// ─────────────────────────────────────────────────────────────────────────────

class _AccountsBody extends ConsumerWidget {
  final List<AccountModel> accounts;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;

  const _AccountsBody({
    required this.accounts,
    required this.c,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendable = accounts.where((a) => a.type.isSpendable).toList();
    final savings = accounts.where((a) => a.type == AccountType.savings).toList();
    final credit = accounts.where((a) => a.type == AccountType.credit).toList();

    if (accounts.isEmpty) {
      return _EmptyState(c: c, cs: cs);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _SummaryCard(c: c, cs: cs, isDark: isDark),
        const SizedBox(height: 24),
        if (spendable.isNotEmpty) ...[
          _SectionHeader(
            title: ref.tr('accounts.spendable_money'),
            c: c,
          ),
          const SizedBox(height: 8),
          ...spendable.map((a) => _AccountCard(account: a, c: c, cs: cs)),
          const SizedBox(height: 20),
        ],
        if (savings.isNotEmpty) ...[
          _SectionHeader(
            title: ref.tr('accounts.saved_for_goals'),
            c: c,
          ),
          const SizedBox(height: 8),
          ...savings.map((a) => _AccountCard(account: a, c: c, cs: cs)),
          const SizedBox(height: 20),
        ],
        if (credit.isNotEmpty) ...[
          _SectionHeader(
            title: ref.tr('accounts.owed'),
            c: c,
          ),
          const SizedBox(height: 8),
          ...credit.map((a) => _AccountCard(account: a, c: c, cs: cs)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends ConsumerWidget {
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;

  const _SummaryCard({required this.c, required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: ref.tr('accounts.available'),
            value: summary?.available,
            color: c.income,
            flex: 2,
          ),
          Container(width: 1, height: 40, color: c.border),
          _SummaryItem(
            label: ref.tr('accounts.saved'),
            value: summary?.saved,
            color: const Color(0xFF2F7155),
            flex: 2,
          ),
          if ((summary?.owed ?? 0) > 0) ...[
            Container(width: 1, height: 40, color: c.border),
            _SummaryItem(
              label: ref.tr('accounts.owed'),
              value: summary?.owed,
              color: c.expense,
              flex: 2,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends ConsumerWidget {
  final String label;
  final double? value;
  final Color color;
  final int flex;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.flex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final currencyState = ref.watch(currencyNotifierProvider);

    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          value == null
              ? Container(
                  height: 18,
                  width: 72,
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  CurrencyFormatter.format(value!, currency: currencyState.baseCurrency),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final FinPaColors c;

  const _SectionHeader({required this.title, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.muted,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Account Card
// ─────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final FinPaColors c;
  final ColorScheme cs;

  const _AccountCard({
    required this.account,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = account.type == AccountType.credit;
    final isSavings = account.type == AccountType.savings;
    final balanceColor = isCredit ? c.expense : cs.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCredit ? c.expense.withOpacity(0.3) : c.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ícono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCredit
                      ? c.expense.withOpacity(0.1)
                      : const Color(0xFF2F7155).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  account.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              // nombre + banco
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (account.bankName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.bankName!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // saldo
              Text(
                _f(account.balance, account: account),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: balanceColor,
                ),
              ),
            ],
          ),
          // barra de progreso para savings
          if (isSavings) ...[
            const SizedBox(height: 10),
            _SavingsProgressBar(balance: account.balance, c: c),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Savings Progress Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SavingsProgressBar extends ConsumerWidget {
  final double balance;
  final FinPaColors c;

  const _SavingsProgressBar({required this.balance, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Progreso visual mínimo para mostrar que hay algo guardado
    final hasBalance = balance > 0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasBalance ? 0.45 : 0.0, // porcentaje hacia la meta
              backgroundColor: c.cardBg,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2F7155)),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          ref.tr('accounts.saving'),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: c.muted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  final FinPaColors c;
  final ColorScheme cs;

  const _EmptyState({required this.c, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              ref.tr('accounts.no_accounts'),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ref.tr('accounts.add_bank_desc'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: c.muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/accounts/add-bank'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2F7155),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                ref.tr('accounts.add_account'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error State
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends ConsumerWidget {
  final String error;
  final VoidCallback onRetry;
  final FinPaColors c;

  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.c,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: c.expense),
          const SizedBox(height: 12),
          Text(
            ref.tr('accounts.error_loading'),
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry, 
            child: Text(ref.tr('common.retry')),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton Loading
// ─────────────────────────────────────────────────────────────────────────────

class _AccountsSkeleton extends StatelessWidget {
  final FinPaColors c;
  final ColorScheme cs;

  const _AccountsSkeleton({required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // summary placeholder
        Container(
          height: 76,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
        ),
        const SizedBox(height: 24),
        _shimmer(height: 14, width: 120, c: c),
        const SizedBox(height: 10),
        ...List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 72,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmer({
    required double height,
    required double width,
    required FinPaColors c,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
