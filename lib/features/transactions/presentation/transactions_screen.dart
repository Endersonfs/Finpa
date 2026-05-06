import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../domain/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../../core/providers/language_provider.dart';

// ── Constantes de categoría ───────────────────────────────────────────────────

const _kEmoji = <String, String>{
  'food': '🍔',
  'transport': '🚗',
  'entertainment': '🎬',
  'services': '💡',
  'health': '💊',
  'salary': '💰',
  'freelance': '💻',
  'shopping': '🛍️',
  'investment': '📈',
  'gift': '🎁',
  'education': '📚',
  'housing': '🏠',
  'clothing': '👗',
  'business': '🏪',
  'other': '📊',
};

const _kBgLight = <String, Color>{
  'food': Color(0xFFFFEEEE),
  'transport': Color(0xFFEEF2FF),
  'entertainment': Color(0xFFF3F0FF),
  'services': Color(0xFFECFDF5),
  'health': Color(0xFFEFF6FF),
  'salary': Color(0xFFECFDF5),
  'freelance': Color(0xFFEEF2FF),
  'shopping': Color(0xFFFFF7ED),
  'investment': Color(0xFFF0FDF4),
  'gift': Color(0xFFFDF4FF),
};

const _kBgDark = <String, Color>{
  'food': Color(0xFF2D1515),
  'transport': Color(0xFF1A2040),
  'entertainment': Color(0xFF1E1535),
  'services': Color(0xFF0D2820),
  'health': Color(0xFF0D1E30),
  'salary': Color(0xFF0D2820),
  'freelance': Color(0xFF1A2040),
  'shopping': Color(0xFF2D1D0D),
  'investment': Color(0xFF0D2010),
  'gift': Color(0xFF231535),
};

const _kFallbackBgLight = Color(0xFFF0F2F8);
const _kFallbackBgDark = Color(0xFF1A2040);

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filter;
  bool _showSearch = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _dateHeader(DateTime date, WidgetRef ref) {
    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    final lang = ref.watch(languageNotifierProvider).locale.languageCode;
    return DateFormat('d MMM', lang == 'es' ? 'es' : 'en').format(date);
  }

  List<Transaction> _applyFilters(List<Transaction> all) {
    var list = all.toList();
    if (_filter != null) {
      list = list.where((t) => t.type == _filter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((t) =>
              (t.description?.toLowerCase().contains(q) ?? false) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> list, WidgetRef ref) {
    final map = <String, List<Transaction>>{};
    for (final t in list) {
      final key = _dateHeader(t.date, ref);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyState = ref.watch(currencyNotifierProvider);

    return Scaffold(
      appBar: _buildAppBar(c, cs, isDark, ref),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showSearch) _SearchBar(controller: _searchCtrl, onChanged: (v) => setState(() => _search = v), ref: ref),
          _FilterChips(
            current: _filter,
            onChanged: (v) => setState(() => _filter = v),
            c: c,
            cs: cs,
            ref: ref,
          ),
          _SummaryCards(c: c, cs: cs),
          const SizedBox(height: 8),
          Expanded(child: _TransactionList(
            filter: _filter,
            search: _search,
            applyFilters: _applyFilters,
            groupByDate: (list) => _groupByDate(list, ref),
            c: c,
            cs: cs,
            isDark: isDark,
            baseCurrency: currencyState.baseCurrency,
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: const Color(0xFF2F7155),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          ref.tr('common.add'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  AppBar _buildAppBar(FinPaColors c, ColorScheme cs, bool isDark, WidgetRef ref) {
    return AppBar(
      title: Text(
        ref.tr('transactions.title'),
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
          ),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _search = '';
                _searchCtrl.clear();
              }
            });
          },
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final WidgetRef ref;
  const _SearchBar({required this.controller, required this.onChanged, required this.ref});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: ref.tr('common.search'),
          prefixIcon: Icon(Icons.search, color: c.muted, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TransactionType? current;
  final ValueChanged<TransactionType?> onChanged;
  final FinPaColors c;
  final ColorScheme cs;
  final WidgetRef ref;

  const _FilterChips({
    required this.current,
    required this.onChanged,
    required this.c,
    required this.cs,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(label: 'All', active: current == null, onTap: () => onChanged(null), c: c, cs: cs),
          const SizedBox(width: 8),
          _Chip(label: ref.tr('transactions.income'), active: current == TransactionType.income, onTap: () => onChanged(TransactionType.income), c: c, cs: cs),
          const SizedBox(width: 8),
          _Chip(label: ref.tr('transactions.expense'), active: current == TransactionType.expense, onTap: () => onChanged(TransactionType.expense), c: c, cs: cs),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final FinPaColors c;
  final ColorScheme cs;
  const _Chip({required this.label, required this.active, required this.onTap, required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2F7155) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends ConsumerWidget {
  final FinPaColors c;
  final ColorScheme cs;
  const _SummaryCards({required this.c, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final currencyState = ref.watch(currencyNotifierProvider);
    final data = summaryAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: ref.tr('transactions.income'),
              amount: data?['income'],
              icon: Icons.arrow_upward_rounded,
              color: c.income,
              c: c,
              cs: cs,
              currency: currencyState.baseCurrency,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: ref.tr('transactions.expense'),
              amount: data?['expense'],
              icon: Icons.arrow_downward_rounded,
              color: c.expense,
              c: c,
              cs: cs,
              currency: currencyState.baseCurrency,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double? amount;
  final IconData icon;
  final Color color;
  final FinPaColors c;
  final ColorScheme cs;
  final AppCurrency currency;

  const _SummaryCard({required this.label, required this.amount, required this.icon, required this.color, required this.c, required this.cs, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: c.muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                if (amount == null)
                  _SkeletonBox(width: 60, height: 12, radius: 4)
                else
                  Text(
                    CurrencyFormatter.format(amount!, currency: currency),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final TransactionType? filter;
  final String search;
  final List<Transaction> Function(List<Transaction>) applyFilters;
  final Map<String, List<Transaction>> Function(List<Transaction>) groupByDate;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;
  final AppCurrency baseCurrency;

  const _TransactionList({required this.filter, required this.search, required this.applyFilters, required this.groupByDate, required this.c, required this.cs, required this.isDark, required this.baseCurrency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

    return txAsync.when(
      loading: () => _LoadingList(c: c, cs: cs),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (all) {
        final filtered = applyFilters(all);
        if (filtered.isEmpty) return Center(child: Text(ref.tr('transactions.no_transactions')));
        final groups = groupByDate(filtered);
        final keys = groups.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: keys.fold<int>(0, (sum, k) => sum + 1 + (groups[k]?.length ?? 0)),
          itemBuilder: (context, index) {
            int cursor = 0;
            for (final key in keys) {
              final items = groups[key]!;
              if (index == cursor) return _DateHeader(label: key, c: c, cs: cs);
              cursor++;
              if (index < cursor + items.length) {
                final tx = items[index - cursor];
                final account = accounts.where((a) => a.id == tx.accountId).firstOrNull;
                final transactionCurrency = account?.currency ?? AppCurrency.dop;
                final displayAmount = currencyNotifier.convert(tx.amount, transactionCurrency, baseCurrency);

                return _TransactionTile(
                  transaction: tx,
                  displayAmount: displayAmount,
                  displayCurrency: baseCurrency,
                  c: c, cs: cs, isDark: isDark,
                  ref: ref,
                );
              }
              cursor += items.length;
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  final FinPaColors c;
  final ColorScheme cs;
  const _DateHeader({required this.label, required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final double displayAmount;
  final AppCurrency displayCurrency;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;
  final WidgetRef ref;

  const _TransactionTile({required this.transaction, required this.displayAmount, required this.displayCurrency, required this.c, required this.cs, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final emoji = _kEmoji[t.category] ?? '📊';
    final bgMap = isDark ? _kBgDark : _kBgLight;
    final emojiBoxBg = bgMap[t.category] ?? (isDark ? _kFallbackBgDark : _kFallbackBgLight);
    final amountColor = t.isIncome ? c.income : c.expense;
    final prefix = t.isIncome ? '+' : '-';
    final timeStr = DateFormat('HH:mm').format(t.date);

    return GestureDetector(
      onTap: () => context.push('/transactions/${t.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: emojiBoxBg, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.description?.isNotEmpty == true ? t.description! : ref.tr('categories.${t.category}'), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${ref.tr('categories.${t.category}')} · $timeStr', style: GoogleFonts.inter(fontSize: 11, color: c.muted)),
                ],
              ),
            ),
            Text(
              '$prefix${CurrencyFormatter.format(displayAmount, currency: displayCurrency)}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  final FinPaColors c;
  final ColorScheme cs;
  const _LoadingList({required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(padding: const EdgeInsets.only(top: 8), itemCount: 5, itemBuilder: (context, i) => _TileSkeleton(c: c, cs: cs));
  }
}

class _TileSkeleton extends StatefulWidget {
  final FinPaColors c;
  final ColorScheme cs;
  const _TileSkeleton({required this.c, required this.cs});

  @override
  State<_TileSkeleton> createState() => _TileSkeletonState();
}

class _TileSkeletonState extends State<_TileSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(opacity: _anim.value, child: Container(margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: widget.cs.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: widget.c.border)), child: Row(children: [_SkeletonBox(width: 40, height: 40, radius: 10), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_SkeletonBox(width: 120, height: 12, radius: 4), const SizedBox(height: 6), _SkeletonBox(width: 80, height: 10, radius: 4)])), _SkeletonBox(width: 64, height: 12, radius: 4)]))),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width, height, radius;
  const _SkeletonBox({required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(width: width, height: height, decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0), borderRadius: BorderRadius.circular(radius)));
  }
}
