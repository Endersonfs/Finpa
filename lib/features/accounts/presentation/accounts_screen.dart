import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/currency_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/compact_amount_text.dart';
import '../domain/account_model.dart';
import '../providers/accounts_provider.dart';
import '../../../../core/constants/currencies.dart';
import '../../../core/providers/language_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final summary = ref.watch(financialSummaryProvider);
    final currencyState = ref.watch(currencyNotifierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          ref.tr('accounts.title'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: ref.tr('accounts.transfer'),
            onPressed: () => context.push('/accounts/transfer'),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const _AccountsSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopSummary(
                summary: summary,
                c: c,
                cs: cs,
                isDark: isDark,
                baseCurrency: currencyState.baseCurrency,
                ref: ref,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (accounts.any((a) => a.type != AccountType.credit)) ...[
                    _SectionHeader(title: ref.tr('accounts.assets').toUpperCase(), c: c),
                    const SizedBox(height: 12),
                    ...accounts
                        .where((a) => a.type != AccountType.credit)
                        .map((a) => _AccountCard(account: a, c: c, cs: cs)),
                    const SizedBox(height: 24),
                  ],
                  if (accounts.any((a) => a.type == AccountType.credit)) ...[
                    _SectionHeader(title: ref.tr('accounts.liabilities').toUpperCase(), c: c),
                    const SizedBox(height: 12),
                    ...accounts
                        .where((a) => a.type == AccountType.credit)
                        .map((a) => _AccountCard(account: a, c: c, cs: cs)),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/accounts/add-bank'),
        backgroundColor: const Color(0xFF2F7155),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(ref.tr('accounts.add_account'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  final FinancialSummary? summary;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;
  final AppCurrency baseCurrency;
  final WidgetRef ref;

  const _TopSummary({
    required this.summary,
    required this.c,
    required this.cs,
    required this.isDark,
    required this.baseCurrency,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Text(
              'NET WORTH',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            CompactAmountText(
              amount: summary?.netWorth ?? 0,
              currency: baseCurrency,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _SummaryMini(
                  label: ref.tr('accounts.available'),
                  amount: summary?.available ?? 0,
                  color: const Color(0xFF059669),
                  baseCurrency: baseCurrency,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: c.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _SummaryMini(
                  label: ref.tr('accounts.owed'),
                  amount: summary?.owed ?? 0,
                  color: c.expense,
                  baseCurrency: baseCurrency,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final AppCurrency baseCurrency;

  const _SummaryMini({
    required this.label,
    required this.amount,
    required this.color,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          CompactAmountText(
            amount: amount,
            currency: baseCurrency,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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
        letterSpacing: 0.8,
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final AccountModel account;
  final FinPaColors c;
  final ColorScheme cs;

  const _AccountCard({
    required this.account,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCredit = account.type == AccountType.credit;
    final isSavings = account.type == AccountType.savings;
    final balanceColor = isCredit ? c.expense : cs.onSurface;
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

    final displayBalance = currencyNotifier.convert(
      account.balance,
      account.currency,
      currencyState.baseCurrency,
    );

    return GestureDetector(
      onTap: () => context.push('/accounts/${account.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCredit ? c.expense.withValues(alpha: 0.3) : c.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCredit
                        ? c.expense.withValues(alpha: 0.1)
                        : const Color(0xFF2F7155).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    account.type.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
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
                CompactAmountText(
                  amount: displayBalance,
                  currency: currencyState.baseCurrency,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            if (isSavings) ...[
              const SizedBox(height: 10),
              _SavingsProgressBar(balance: account.balance, c: c, ref: ref),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavingsProgressBar extends StatelessWidget {
  final double balance;
  final FinPaColors c;
  final WidgetRef ref;
  const _SavingsProgressBar({required this.balance, required this.c, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ref.tr('accounts.saving'),
              style: GoogleFonts.inter(fontSize: 11, color: c.muted),
            ),
            Text(
              '65%', // Placeholder
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2F7155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0.65,
            backgroundColor: Color(0xFFE2E6F0),
            valueColor: AlwaysStoppedAnimation(Color(0xFF2F7155)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
