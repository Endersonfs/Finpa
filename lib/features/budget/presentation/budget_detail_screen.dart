import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../domain/budget_model.dart';
import '../providers/budget_provider.dart';

import '../../../core/providers/language_provider.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String id;
  const BudgetDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final textPrimary = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);

    final budgetsAsync = ref.watch(budgetsProvider);

    return budgetsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (budgets) {
        final budget = budgets.where((b) => b.id == id).firstOrNull;
        if (budget == null) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text(ref.tr('common.error'))));
        }

        const categoryEmojis = {
          'food': '🍔', 'transport': '🚗', 'entertainment': '🎬', 'services': '💡',
          'health': '💊', 'salary': '💰', 'freelance': '💻', 'shopping': '🛍️',
          'investment': '📈', 'gift': '🎁', 'education': '📚', 'housing': '🏠',
          'clothing': '👗', 'business': '🏪', 'other': '📊',
        };

        final label = ref.tr('categories.${budget.category}');
        final emoji = categoryEmojis[budget.category] ?? '📊';

        // Conversiones globales
        final dispSpent = currencyNotifier.convert(budget.spent, AppCurrency.dop, currencyState.baseCurrency);
        final dispLimit = currencyNotifier.convert(budget.limitAmount, AppCurrency.dop, currencyState.baseCurrency);
        final dispRemaining = dispLimit - dispSpent;

        return Scaffold(
          appBar: AppBar(
            title: Text(ref.tr('budget.title')),
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
                      Text(emoji, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(label, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: budget.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(budget.percentage * 100).round()}% ${ref.tr('goals.progress')}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: budget.statusColor),
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
                    widthFactor: budget.percentage.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(decoration: BoxDecoration(color: budget.statusColor, borderRadius: BorderRadius.circular(7))),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _AmountCol(label: ref.tr('dashboard.expense'), amount: dispSpent, color: budget.statusColor, currency: currencyState.baseCurrency),
                    _AmountCol(label: ref.tr('budget.limit'), amount: dispLimit, color: textPrimary, currency: currencyState.baseCurrency),
                    _AmountCol(label: ref.tr('goals.remaining'), amount: dispRemaining, color: dispRemaining >= 0 ? c.income : c.expense, currency: currencyState.baseCurrency),
                  ],
                ),
                const SizedBox(height: 40),
                Text(ref.tr('settings.title'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.notifications_active_outlined,
                  label: ref.tr('settings.limit_alert'),
                  value: budget.alertAt80 ? 'Enabled' : 'Disabled',
                  c: c, textPrimary: textPrimary,
                ),
                _InfoTile(
                  icon: Icons.calendar_month_outlined,
                  label: ref.tr('reports.month'),
                  value: '${budget.month}/${budget.year}',
                  c: c, textPrimary: textPrimary,
                ),
                const SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () => _confirmDelete(context, ref, budget),
                    child: Text(ref.tr('common.delete'), style: TextStyle(color: c.expense, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) async {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('common.delete')),
        content: Text(ref.tr('budget.delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.tr('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.tr('common.delete'), style: TextStyle(color: c.expense))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(budgetNotifierProvider.notifier).remove(budget.id);
      if (context.mounted) context.go('/budget');
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
          FittedBox(fit: BoxFit.scaleDown, child: Text(CurrencyFormatter.format(amount, currency: currency), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color))),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final FinPaColors c;
  final Color textPrimary;
  const _InfoTile({required this.icon, required this.label, required this.value, required this.c, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border, width: 0.5))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: textPrimary))),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        ],
      ),
    );
  }
}
