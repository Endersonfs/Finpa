import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/widgets/compact_amount_text.dart';
import '../domain/account_model.dart';
import '../providers/accounts_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../core/providers/language_provider.dart';

class AccountDetailScreen extends ConsumerWidget {
  final String id;
  const AccountDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

    return accountsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (accounts) {
        final account = accounts.where((a) => a.id == id).firstOrNull;
        if (account == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(ref.tr('accounts.account_not_found'))));

        final displayBalance = currencyNotifier.convert(account.balance, account.currency, currencyState.baseCurrency);

        return Scaffold(
          appBar: AppBar(title: Text(account.name)),
          body: Column(
            children: [
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(account.type.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    CompactAmountText(amount: displayBalance, currency: currencyState.baseCurrency, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700)),
                    Text('${ref.tr('accounts.current_balance_in')} ${currencyState.baseCurrency.code}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              Expanded(
                child: _AccountTransactionsList(accountId: id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountTransactionsList extends ConsumerWidget {
  final String accountId;
  const _AccountTransactionsList({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final txs = all.where((t) => t.accountId == accountId).toList();
        if (txs.isEmpty) return Center(child: Text(ref.tr('accounts.no_transactions_account')));

        return ListView.builder(
          itemCount: txs.length,
          itemBuilder: (context, i) {
            final t = txs[i];
            final account = accounts.where((a) => a.id == t.accountId).firstOrNull;
            final txCurr = account?.currency ?? AppCurrency.dop;
            final dispAmt = currencyNotifier.convert(t.amount, txCurr, currencyState.baseCurrency);
            final color = t.isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);

            return ListTile(
              title: Text(t.description?.isNotEmpty == true ? t.description! : ref.tr('categories.${t.category}')),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
              trailing: CompactAmountText(amount: dispAmt, currency: currencyState.baseCurrency, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            );
          },
        );
      },
    );
  }
}
