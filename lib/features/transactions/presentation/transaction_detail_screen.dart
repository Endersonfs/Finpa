import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/widgets/compact_amount_text.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/transaction_provider.dart';

import '../../../core/providers/language_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final lang = ref.watch(languageNotifierProvider).locale.languageCode;

    return txAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (list) {
        final tx = list.where((t) => t.id == id).firstOrNull;
        if (tx == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(ref.tr('transactions.no_transactions'))));

        final account = accounts.where((a) => a.id == tx.accountId).firstOrNull;
        final txCurrency = account?.currency ?? AppCurrency.dop;
        final displayAmount = currencyNotifier.convert(tx.amount, txCurrency, currencyState.baseCurrency);
        final color = tx.isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);

        return Scaffold(
          appBar: AppBar(title: Text(ref.tr('transactions.details'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(tx.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(tx.isIncome ? ref.tr('transactions.income') : ref.tr('transactions.expense'), style: GoogleFonts.inter(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                CompactAmountText(amount: displayAmount, currency: currencyState.baseCurrency, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 40),
                _InfoTile(label: ref.tr('transactions.description'), value: tx.description?.isNotEmpty == true ? tx.description! : ref.tr('categories.${tx.category}')),
                _InfoTile(label: ref.tr('transactions.date'), value: DateFormat('dd MMMM yyyy, HH:mm', lang == 'es' ? 'es' : 'en').format(tx.date)),
                _InfoTile(label: ref.tr('transactions.account'), value: account?.name ?? 'Desconocida'),
                _InfoTile(label: ref.tr('transactions.category'), value: ref.tr('categories.${tx.category}').toUpperCase()),
                const SizedBox(height: 40),
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit_outlined), label: Text(ref.tr('common.edit'))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
