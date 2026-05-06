import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/budget_repository.dart';
import '../domain/budget_model.dart';
import '../providers/budget_provider.dart';

import '../../../core/providers/language_provider.dart';

const _kEmoji = {
  'food': '🍔', 'transport': '🚗', 'entertainment': '🎬', 'services': '💡',
  'health': '💊', 'salary': '💰', 'freelance': '💻', 'shopping': '🛍️',
  'investment': '📈', 'gift': '🎁', 'education': '📚', 'housing': '🏠',
  'clothing': '👗', 'business': '🏪', 'other': '📊',
};

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final repo = ref.watch(budgetRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('budget.title')),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/budget/add')),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => const _BudgetSkeleton(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (budgets) {
          if (budgets.isEmpty) return const _EmptyState();
          return _BudgetContent(budgets: budgets, repo: repo, ref: ref);
        },
      ),
    );
  }
}

class _BudgetContent extends StatelessWidget {
  final List<Budget> budgets;
  final BudgetRepository repo;
  final WidgetRef ref;
  const _BudgetContent({required this.budgets, required this.repo, required this.ref});

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final totalLimit = budgets.fold(0.0, (s, b) => s + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
    final dispLimit = currencyNotifier.convert(totalLimit, AppCurrency.dop, currencyState.baseCurrency);
    final dispSpent = currencyNotifier.convert(totalSpent, AppCurrency.dop, currencyState.baseCurrency);
    final percentage = dispLimit > 0 ? dispSpent / dispLimit : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2F7155), Color(0xFF6BC99D)]), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('budget.monthly_limit'), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
                    Text('${(percentage * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: Stack(children: [Container(height: 8, color: Colors.white.withValues(alpha: 0.2)), FractionallySizedBox(widthFactor: percentage.clamp(0.0, 1.0), child: Container(height: 8, color: Colors.white))])),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${CurrencyFormatter.format(dispSpent, currency: currencyState.baseCurrency)} ${ref.tr('transactions.expense').toLowerCase()}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                    Text('${ref.tr('budget.limit')} ${CurrencyFormatter.format(dispLimit, currency: currencyState.baseCurrency)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 0), child: Text(ref.tr('dashboard.by_category'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface))),
          const SizedBox(height: 8),
          ...budgets.map((b) {
            final rowLimit = currencyNotifier.convert(b.limitAmount, AppCurrency.dop, currencyState.baseCurrency);
            final rowSpent = currencyNotifier.convert(b.spent, AppCurrency.dop, currencyState.baseCurrency);
            return _BudgetRow(
              budget: b, displayLimit: rowLimit, displaySpent: rowSpent, displayCurrency: currencyState.baseCurrency, ref: ref,
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(ref.tr('common.delete')),
                    content: Text(ref.tr('budget.delete_confirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.tr('common.cancel'))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.tr('common.delete'), style: const TextStyle(color: Color(0xFFDC2626)))),
                    ],
                  ),
                );
                if (confirmed == true) ref.read(budgetNotifierProvider.notifier).remove(b.id);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Budget budget;
  final double displayLimit;
  final double displaySpent;
  final AppCurrency displayCurrency;
  final VoidCallback onDelete;
  final WidgetRef ref;
  const _BudgetRow({required this.budget, required this.displayLimit, required this.displaySpent, required this.displayCurrency, required this.onDelete, required this.ref});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final pct = displayLimit > 0 ? displaySpent / displayLimit : 0.0;
    final statusColor = pct >= 1.0 ? c.expense : (pct >= 0.8 ? Colors.orange : const Color(0xFF2F7155));
    final emoji = _kEmoji[budget.category] ?? '📊';
    final label = ref.tr('categories.${budget.category}');

    return GestureDetector(
      onTap: () => context.push('/budget/${budget.id}'),
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      const Spacer(),
                      Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(children: [Container(height: 3, decoration: BoxDecoration(color: c.cardBg, borderRadius: BorderRadius.circular(2))), FractionallySizedBox(widthFactor: pct.clamp(0.0, 1.0), child: Container(height: 3, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))))]),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${CurrencyFormatter.format(displaySpent, currency: displayCurrency)} ${ref.tr('dashboard.expense').toLowerCase()}', style: GoogleFonts.inter(fontSize: 11, color: c.muted)),
                      const Spacer(),
                      Text('${ref.tr('education.lesson_of')} ${CurrencyFormatter.format(displayLimit, currency: displayCurrency)}', style: GoogleFonts.inter(fontSize: 11, color: c.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSkeleton extends StatefulWidget {
  const _BudgetSkeleton();
  @override
  State<_BudgetSkeleton> createState() => _BudgetSkeletonState();
}

class _BudgetSkeletonState extends State<_BudgetSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);
    return AnimatedBuilder(animation: _anim, builder: (context, _) { final color = base.withValues(alpha: _anim.value); return SingleChildScrollView(padding: const EdgeInsets.only(bottom: 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), height: 100, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18))), const SizedBox(height: 24), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(height: 16, width: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)))), const SizedBox(height: 12), ...List.generate(3, (_) => Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), height: 82, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))))])); });
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_balance_wallet_outlined, size: 64, color: c.muted), const SizedBox(height: 16), Text(ref.tr('budget.no_budgets'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)), const SizedBox(height: 8), Text(ref.tr('budget.create_first'), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: c.muted))])));
  }
}
