import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/compact_amount_text.dart';
import '../domain/account_model.dart';
import '../providers/accounts_provider.dart';
import '../../../core/providers/language_provider.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});
  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  AccountModel? _from; AccountModel? _to;
  final _amountCtrl = TextEditingController(); double _amount = 0;

  @override
  void initState() { super.initState(); _amountCtrl.addListener(() { final raw = _amountCtrl.text.replaceAll(',', '.'); setState(() => _amount = double.tryParse(raw) ?? 0); }); }
  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  bool get _canSubmit => _from != null && _to != null && _from!.id != _to!.id && _amount > 0;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (_amount > _from!.balance) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('common.error'))));
      return;
    }
    final ok = await ref.read(transferNotifierProvider.notifier).transfer(fromAccountId: _from!.id, toAccountId: _to!.id, amount: _amount);
    if (!mounted) return;
    if (ok) { Navigator.of(context).pop(); }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currencyState = ref.watch(currencyNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('accounts.transfer'), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17))),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            Text(ref.tr('accounts.from_account'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _AccountDropdown(hint: ref.tr('accounts.choose_source'), accounts: accounts.where((a) => a.type.isSpendable).toList(), selected: _from, onChanged: (a) => setState(() => _from = a), baseCurrency: currencyState.baseCurrency),
            const SizedBox(height: 20),
            Text(ref.tr('accounts.to_account'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _AccountDropdown(hint: ref.tr('accounts.choose_target'), accounts: accounts.where((a) => a.id != _from?.id).toList(), selected: _to, onChanged: (a) => setState(() => _to = a), baseCurrency: currencyState.baseCurrency),
            const SizedBox(height: 32),
            Center(child: Column(children: [
              Text(ref.tr('accounts.how_much'), style: GoogleFonts.inter(fontSize: 13, color: c.muted)),
              const SizedBox(height: 12),
              SizedBox(width: 220, child: TextField(controller: _amountCtrl, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700), decoration: InputDecoration(hintText: '0', prefixText: '${currencyState.baseCurrency.symbol} ', border: InputBorder.none), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))])),
            ])),
            if (_canSubmit) ...[
              const SizedBox(height: 24),
              _BalancePreview(from: _from!, to: _to!, amount: _amount, baseCurrency: currencyState.baseCurrency, ref: ref),
            ],
            const SizedBox(height: 32),
            FilledButton(onPressed: _canSubmit ? _submit : null, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2F7155), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(ref.tr('common.confirm'), style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _AccountDropdown extends ConsumerWidget {
  final String hint; final List<AccountModel> accounts; final AccountModel? selected; final ValueChanged<AccountModel?> onChanged; final AppCurrency baseCurrency;
  const _AccountDropdown({required this.hint, required this.accounts, required this.selected, required this.onChanged, required this.baseCurrency});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).extension<FinPaColors>()!.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<AccountModel>(
        isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 14)), value: selected, onChanged: onChanged,
        items: accounts.map((a) {
          final displayBalance = currencyNotifier.convert(a.balance, a.currency, baseCurrency);
          return DropdownMenuItem(value: a, child: Row(children: [
            Text(a.type.emoji, style: const TextStyle(fontSize: 16)), const SizedBox(width: 10),
            Expanded(child: Text(a.name, style: const TextStyle(fontSize: 14))),
            CompactAmountText(amount: displayBalance, currency: baseCurrency, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), useFullOnTap: false),
          ]));
        }).toList(),
      )),
    );
  }
}

class _BalancePreview extends ConsumerWidget {
  final AccountModel from, to; final double amount; final AppCurrency baseCurrency; final WidgetRef ref;
  const _BalancePreview({required this.from, required this.to, required this.amount, required this.baseCurrency, required this.ref});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final fromBefore = currencyNotifier.convert(from.balance, from.currency, baseCurrency);
    final fromAfter = currencyNotifier.convert(from.balance - amount, from.currency, baseCurrency);
    final toBefore = currencyNotifier.convert(to.balance, to.currency, baseCurrency);
    final toAfter = currencyNotifier.convert(to.balance + amount, to.currency, baseCurrency);

    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).extension<FinPaColors>()!.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ref.tr('accounts.balances_after'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 12),
        _BalanceRow(name: from.name, emoji: from.type.emoji, before: fromBefore, after: fromAfter, currency: baseCurrency, isRed: true),
        const SizedBox(height: 10),
        _BalanceRow(name: to.name, emoji: to.type.emoji, before: toBefore, after: toAfter, currency: baseCurrency, isRed: false),
      ]),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String name, emoji; final double before, after; final AppCurrency currency; final bool isRed;
  const _BalanceRow({required this.name, required this.emoji, required this.before, required this.after, required this.currency, required this.isRed});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji), const SizedBox(width: 8), Expanded(child: Text(name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
      CompactAmountText(amount: before, currency: currency, style: const TextStyle(fontSize: 12, color: Colors.grey), useFullOnTap: false),
      const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
      CompactAmountText(amount: after, currency: currency, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isRed && after < 0 ? Colors.red : null)),
    ]);
  }
}
