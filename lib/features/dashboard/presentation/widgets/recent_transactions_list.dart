import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/accounts/providers/accounts_provider.dart';
import '../../../../features/transactions/domain/transaction.dart';
import '../../../../core/providers/language_provider.dart';

class RecentTransactionsList extends ConsumerWidget {
  final List<Transaction>? transactions;

  const RecentTransactionsList({super.key, this.transactions});

  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];

    if (transactions == null) return _TransactionSkeleton();

    if (transactions!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            ref.tr('transactions.no_transactions'),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8892B0) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...transactions!.map((t) {
          final account = accounts.where((a) => a.id == t.accountId).firstOrNull;
          final transactionCurrency = account?.currency ?? AppCurrency.dop;
          final displayAmount = currencyNotifier.convert(
            t.amount,
            transactionCurrency,
            currencyState.baseCurrency,
          );

          return _TransactionTile(
            transaction: t,
            displayAmount: displayAmount,
            displayCurrency: currencyState.baseCurrency,
            isDark: isDark,
            timeFmt: _timeFmt,
            ref: ref,
          );
        }),
        // Ver todos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => context.push('/transactions'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                '${ref.tr('dashboard.view_all')} →',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F7155),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final double displayAmount;
  final AppCurrency displayCurrency;
  final bool isDark;
  final DateFormat timeFmt;
  final WidgetRef ref;

  const _TransactionTile({
    required this.transaction,
    required this.displayAmount,
    required this.displayCurrency,
    required this.isDark,
    required this.timeFmt,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final display = (isDark
            ? _kDisplayDark[transaction.category]
            : _kDisplay[transaction.category]) ??
        _CatDisplay('📊', isDark ? const Color(0xFF1E2840) : const Color(0xFFF0F2F8));

    final amountColor = transaction.isIncome
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);

    final amountColorDark = transaction.isIncome
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);

    final textPrimary   = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary = isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: display.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(display.emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? ref.tr('categories.${transaction.category}'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ref.tr('categories.${transaction.category}')} · ${timeFmt.format(transaction.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.format(displayAmount, currency: displayCurrency)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? amountColorDark : amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatDisplay {
  final String emoji;
  final Color bg;
  const _CatDisplay(this.emoji, this.bg);
}

const _kDisplay = <String, _CatDisplay>{
  'food':          _CatDisplay('🍔', Color(0xFFFFEEEE)),
  'transport':     _CatDisplay('🚗', Color(0xFFEEF2FF)),
  'entertainment': _CatDisplay('🎬', Color(0xFFF3F0FF)),
  'health':        _CatDisplay('🏥', Color(0xFFEFF6FF)),
  'services':      _CatDisplay('💡', Color(0xFFECFDF5)),
  'salary':        _CatDisplay('💰', Color(0xFFECFDF5)),
  'freelance':     _CatDisplay('💻', Color(0xFFEEF2FF)),
  'shopping':      _CatDisplay('🛍️', Color(0xFFFFF7ED)),
  'other':         _CatDisplay('📊', Color(0xFFF0F2F8)),
};

const _kDisplayDark = <String, _CatDisplay>{
  'food':          _CatDisplay('🍔', Color(0xFF2D1515)),
  'transport':     _CatDisplay('🚗', Color(0xFF1A2040)),
  'entertainment': _CatDisplay('🎬', Color(0xFF1E1535)),
  'health':        _CatDisplay('🏥', Color(0xFF0D1E30)),
  'services':      _CatDisplay('💡', Color(0xFF0D2820)),
  'salary':        _CatDisplay('💰', Color(0xFF0D2820)),
  'freelance':     _CatDisplay('💻', Color(0xFF1A2040)),
  'shopping':      _CatDisplay('🛍️', Color(0xFF2D1D0D)),
  'other':         _CatDisplay('📊', Color(0xFF1E2840)),
};

class _TransactionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);

    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 80, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              Container(height: 12, width: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ),
    );
  }
}
