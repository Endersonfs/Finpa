import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/compact_amount_text.dart';
import '../domain/goal_model.dart';
import '../providers/goals_provider.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';

import '../../../core/providers/language_provider.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String id;
  const GoalDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final textPrimary = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary = isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (goals) {
        final goal = goals.where((g) => g.id == id).firstOrNull;
        if (goal == null) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text(ref.tr('common.error'))));
        }

        // Conversiones globales usando la moneda real de la meta
        final dispCurrent = currencyNotifier.convert(goal.currentAmount, goal.currency, currencyState.baseCurrency);
        final dispTarget = currencyNotifier.convert(goal.targetAmount, goal.currency, currencyState.baseCurrency);
        final dispRemaining = currencyNotifier.convert(goal.remaining, goal.currency, currencyState.baseCurrency);
        final dispMonthly = currencyNotifier.convert(goal.requiredMonthlySaving, goal.currency, currencyState.baseCurrency);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
            title: Text(ref.tr('goals.title')),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(goal.emoji, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(goal.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: (goal.isCompleted ? c.income : goal.progressColor).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          goal.isCompleted ? ref.tr('goals.completed') : '${(goal.progress * 100).round()}% ${ref.tr('goals.progress')}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: goal.isCompleted ? c.income : goal.progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  height: 14,
                  decoration: BoxDecoration(color: c.cardBg, borderRadius: BorderRadius.circular(7)),
                  clipBehavior: Clip.hardEdge,
                  child: FractionallySizedBox(
                    widthFactor: goal.progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [goal.progressColor.withValues(alpha: 0.7), goal.progressColor]), borderRadius: BorderRadius.circular(7))),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _AmountCol(label: ref.tr('goals.saved'), amount: dispCurrent, color: c.income, currency: currencyState.baseCurrency),
                    _AmountCol(label: ref.tr('goals.goal_target'), amount: dispTarget, color: textPrimary, currency: currencyState.baseCurrency),
                    _AmountCol(label: ref.tr('goals.remaining'), amount: dispRemaining, color: c.expense, currency: currencyState.baseCurrency),
                  ],
                ),
                const SizedBox(height: 32),
                if (goal.deadline != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141928) : const Color(0xFFF0F2F8),
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF2F7155)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${goal.monthsRemaining} ${goal.monthsRemaining == 1 ? ref.tr('goals.month_left') : ref.tr('goals.months_left')} · ${ref.tr('goals.save_monthly')} ',
                                style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
                              ),
                              CompactAmountText(
                                amount: dispMonthly,
                                currency: currencyState.baseCurrency,
                                style: GoogleFonts.inter(
                                  fontSize: 13, 
                                  color: textSecondary, 
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                '/mo',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (!goal.isCompleted)
                  ElevatedButton(
                    onPressed: () => _showDepositSheet(context, ref, goal),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F7155), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(ref.tr('goals.add_saving'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 16),
                Center(child: TextButton(onPressed: () => _confirmDelete(context, ref, goal), child: Text(ref.tr('goals.delete_goal'), style: TextStyle(color: c.expense, fontWeight: FontWeight.w500)))),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDepositSheet(BuildContext context, WidgetRef ref, SavingGoal goal) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => _DepositSheet(goal: goal, ref: ref));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SavingGoal goal) async {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('goals.delete_goal')),
        content: Text(ref.tr('goals.delete_confirm').replaceFirst('{name}', goal.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.tr('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.tr('common.delete'), style: TextStyle(color: c.expense))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(goalNotifierProvider.notifier).remove(goal.id);
      if (context.mounted) context.go('/goals');
    }
  }
}

class _AmountCol extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final AppCurrency currency;
  const _AmountCol({required this.label, required this.amount, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CompactAmountText(
              amount: amount,
              currency: currency,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositSheet extends StatefulWidget {
  final SavingGoal goal;
  final WidgetRef ref;
  const _DepositSheet({required this.goal, required this.ref});
  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _controller = TextEditingController();
  String _amountText = '';
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final currencyState = widget.ref.watch(currencyNotifierProvider);
    final accountsAsync = widget.ref.watch(accountsStreamProvider);

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.ref.tr('goals.add_saving'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _amountText = v),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '${currencyState.baseCurrency.symbol} ',
              hintText: '0',
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.ref.tr('accounts.from_account'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          accountsAsync.when(
            data: (accounts) {
              final spendable = accounts.where((a) => a.type.isSpendable).toList();
              if (spendable.isEmpty) return Text(widget.ref.tr('accounts.no_accounts'));
              _selectedAccountId ??= spendable.first.id;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAccountId,
                    items: spendable.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.type.emoji} ${a.name}'))).toList(),
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(widget.ref.tr('accounts.error_loading')),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_amountText.isNotEmpty && !_isSaving) ? _confirm : null,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F7155), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.ref.tr('common.confirm'), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountText.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;
    setState(() => _isSaving = true);
    try {
      await widget.ref.read(goalNotifierProvider.notifier).deposit(widget.goal.id, amount, accountId: _selectedAccountId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
