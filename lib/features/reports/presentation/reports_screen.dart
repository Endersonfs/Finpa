import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/compact_amount_text.dart';
import '../providers/reports_provider.dart';
import '../../../core/providers/language_provider.dart';

const _monthKeys = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
const _catColors = {
  'food': Color(0xFFDC2626),
  'transport': Color(0xFF2563EB),
  'entertainment': Color(0xFF7C3AED),
  'health': Color(0xFF0891B2),
  'services': Color(0xFF059669),
  'salary': Color(0xFF059669),
  'freelance': Color(0xFF2563EB),
  'shopping': Color(0xFFF59E0B),
  'other': Color(0xFF8892B0)
};
const _catEmojis = {
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
  'other': '📊'
};

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = 'Mes';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final reportsAsync = ref.watch(reportsProvider((month: _selectedMonth, year: _selectedYear)));
    final currencyState = ref.watch(currencyNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('reports.title'))),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'Mes', label: Text(ref.tr('reports.month'))),
                      ButtonSegment(value: 'Año', label: Text(ref.tr('reports.year')))
                    ],
                    selected: {_period},
                    onSelectionChanged: (s) => setState(() => _period = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF2F7155) : Colors.transparent),
                      foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : c.muted),
                    ),
                  ),
                ),
                if (_period == 'Mes') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableMonths(),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = (index + 1) == _selectedMonth;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMonth = index + 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2F7155) : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? const Color(0xFF2F7155) : c.border),
                            ),
                            child: Text(
                              ref.tr('months.${_monthKeys[index]}'),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : c.muted),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                reportsAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: Color(0xFF2F7155)))),
                  error: (e, _) => Padding(padding: const EdgeInsets.only(top: 80), child: Center(child: Text(ref.tr('common.error'), style: GoogleFonts.inter(color: c.expense)))),
                  data: (data) => _ReportsContent(
                    data: data,
                    isDark: isDark,
                    textPrimary: theme.colorScheme.onSurface,
                    surface: theme.colorScheme.surface,
                    muted: c.muted,
                    border: c.border,
                    cardBg: c.cardBg,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    touchedBarIndex: _touchedBarIndex,
                    touchedPieIndex: _touchedPieIndex,
                    onBarTouch: (i) => setState(() => _touchedBarIndex = i),
                    onPieTouch: (i) => setState(() => _touchedPieIndex = i),
                    baseCurrency: currencyState.baseCurrency,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _availableMonths() {
    final now = DateTime.now();
    return _selectedYear == now.year ? now.month : 12;
  }
}

class _ReportsContent extends ConsumerWidget {
  const _ReportsContent({
    required this.data,
    required this.isDark,
    required this.textPrimary,
    required this.surface,
    required this.muted,
    required this.border,
    required this.cardBg,
    required this.selectedMonth,
    required this.selectedYear,
    required this.touchedBarIndex,
    required this.touchedPieIndex,
    required this.onBarTouch,
    required this.onPieTouch,
    required this.baseCurrency,
  });

  final ReportData data;
  final bool isDark;
  final Color textPrimary, surface, muted, border, cardBg;
  final int selectedMonth, selectedYear, touchedBarIndex, touchedPieIndex;
  final ValueChanged<int> onBarTouch, onPieTouch;
  final AppCurrency baseCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBarCard(context, currencyNotifier, ref),
        _buildDonutCard(context, currencyNotifier, ref),
        _buildLineCard(context, currencyNotifier, ref),
        _buildTopExpensesCard(context, currencyNotifier, ref),
      ],
    );
  }

  Widget _buildBarCard(BuildContext context, CurrencyNotifier currencyNotifier, WidgetRef ref) {
    final maxExpense = data.last6Months.map((e) => e.expense).fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('reports.expense_distribution'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
          Text(ref.tr('reports.last_6_months'), style: GoogleFonts.inter(fontSize: 10, color: muted)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxExpense > 0 ? maxExpense * 1.2 : 100,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) => onBarTouch(response?.spot?.touchedBarGroupIndex ?? -1),
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2F7155),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                      CurrencyFormatter.formatCompact(rod.toY, currency: baseCurrency),
                      GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.last6Months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            ref.tr('months.${_monthKeys[data.last6Months[idx].month - 1]}'),
                            style: GoogleFonts.inter(fontSize: 10, color: muted),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0), strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.last6Months.asMap().entries.map((entry) {
                  final converted = entry.value.expense;
                  final isSelected = entry.key == touchedBarIndex || (entry.value.month == selectedMonth && entry.value.year == selectedYear);
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: converted,
                        color: isSelected ? const Color(0xFF2F7155) : (isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0)),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutCard(BuildContext context, CurrencyNotifier currencyNotifier, WidgetRef ref) {
    final categoryExpenses = data.categoryExpenses;
    final totalExpense = categoryExpenses.values.fold(0.0, (a, b) => a + b);
    final entries = categoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final pieSections = entries
        .asMap()
        .entries
        .map((entry) => PieChartSectionData(
              value: entry.value.value,
              color: _catColors[entry.value.key] ?? const Color(0xFF8892B0),
              radius: entry.key == touchedPieIndex ? 38 : 32,
              showTitle: false,
            ))
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('reports.expense_distribution'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
          Text(ref.tr('dashboard.this_month'), style: GoogleFonts.inter(fontSize: 10, color: muted)),
          const SizedBox(height: 16),
          if (categoryExpenses.isEmpty)
            Center(child: Text(ref.tr('transactions.no_transactions'), style: GoogleFonts.inter(color: muted)))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(touchCallback: (event, response) => onPieTouch(response?.touchedSection?.touchedSectionIndex ?? -1)),
                          sections: pieSections,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total', style: GoogleFonts.inter(fontSize: 11, color: muted)),
                          CompactAmountText(
                            amount: totalExpense,
                            currency: baseCurrency,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: _PieLegend(entries: entries, totalExpense: totalExpense, textPrimary: textPrimary, muted: muted, baseCurrency: baseCurrency, ref: ref)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineCard(BuildContext context, CurrencyNotifier currencyNotifier, WidgetRef ref) {
    const incomeColor = Color(0xFF059669), expenseColor = Color(0xFFDC2626);
    final totalIncome = data.last6Months.fold(0.0, (sum, e) => sum + e.income);
    final totalExpense = data.last6Months.fold(0.0, (sum, e) => sum + e.expense);
    final balance = totalIncome - totalExpense;
    final maxValue = data.last6Months.expand((e) => [e.income, e.expense]).fold(0.0, (a, b) => a > b ? a : b);
    final compact = NumberFormat.compact(locale: baseCurrency.locale);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${ref.tr('transactions.income')} vs ${ref.tr('transactions.expense')}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
          Text(ref.tr('reports.last_6_months'), style: GoogleFonts.inter(fontSize: 10, color: muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              _Badge(label: ref.tr('dashboard.income'), amount: totalIncome, color: incomeColor, textPrimary: textPrimary, currency: baseCurrency),
              const SizedBox(width: 8),
              _Badge(label: ref.tr('dashboard.expense'), amount: totalExpense, color: expenseColor, textPrimary: textPrimary, currency: baseCurrency),
              const SizedBox(width: 8),
              _Badge(label: 'Balance', amount: balance, color: balance >= 0 ? incomeColor : expenseColor, textPrimary: textPrimary, currency: baseCurrency, showPlus: balance >= 0),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue * 1.25 : 100,
                groupsSpace: 12,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) => onBarTouch(response?.spot?.touchedBarGroupIndex ?? -1),
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF141928) : Colors.white,
                    tooltipBorder: BorderSide(color: border),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final mData = data.last6Months[groupIndex];
                      final isInc = rodIndex == 0;
                      final val = isInc ? mData.income : mData.expense;
                      return BarTooltipItem(
                        '${ref.tr('months.${_monthKeys[mData.month - 1]}')}\n',
                        GoogleFonts.inter(fontSize: 10, color: muted, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: CurrencyFormatter.formatCompact(val, currency: baseCurrency),
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isInc ? incomeColor : expenseColor),
                          )
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.last6Months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            ref.tr('months.${_monthKeys[data.last6Months[idx].month - 1]}'),
                            style: GoogleFonts.inter(fontSize: 10, color: muted),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, m) => v == 0 ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(right: 4), child: Text(compact.format(v), style: GoogleFonts.inter(fontSize: 10, color: muted))),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0), strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.last6Months
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(toY: e.value.income, color: incomeColor, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                            BarChartRodData(toY: e.value.expense, color: expenseColor, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpensesCard(BuildContext context, CurrencyNotifier currencyNotifier, WidgetRef ref) {
    final categoryExpenses = data.categoryExpenses;
    final totalExpense = categoryExpenses.values.fold(0.0, (a, b) => a + b);
    final sorted = categoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('reports.expense_distribution'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            Center(child: Text(ref.tr('transactions.no_transactions'), style: GoogleFonts.inter(color: muted)))
          else
            ...top5.map((e) => _TopCategoryRow(
                  emoji: _catEmojis[e.key] ?? '📊',
                  label: ref.tr('categories.${e.key}'),
                  amount: e.value,
                  percentage: totalExpense > 0 ? e.value / totalExpense : 0,
                  color: _catColors[e.key] ?? const Color(0xFF8892B0),
                  textPrimary: textPrimary,
                  muted: muted,
                  cardBg: cardBg,
                  currency: baseCurrency,
                )),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final double amount;
  final Color color, textPrimary;
  final AppCurrency currency;
  final bool showPlus;
  const _Badge({required this.label, required this.amount, required this.color, required this.textPrimary, required this.currency, this.showPlus = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              if (showPlus) Text('+', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              Expanded(
                child: CompactAmountText(
                  amount: amount,
                  currency: currency,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              )
            ]),
          ],
        ),
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  const _PieLegend({required this.entries, required this.totalExpense, required this.textPrimary, required this.muted, required this.baseCurrency, required this.ref});
  final List<MapEntry<String, double>> entries;
  final double totalExpense;
  final Color textPrimary, muted;
  final AppCurrency baseCurrency;
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.take(6).map((e) {
        final pct = totalExpense > 0 ? e.value / totalExpense : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _catColors[e.key] ?? const Color(0xFF8892B0), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(ref.tr('categories.${e.key}'), style: GoogleFonts.inter(fontSize: 11, color: muted), overflow: TextOverflow.ellipsis)),
              Text('${(pct * 100).round()}%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  const _TopCategoryRow({required this.emoji, required this.label, required this.amount, required this.percentage, required this.color, required this.textPrimary, required this.muted, required this.cardBg, required this.currency});
  final String emoji, label;
  final double amount, percentage;
  final Color color, textPrimary, muted, cardBg;
  final AppCurrency currency;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                    const Spacer(),
                    CompactAmountText(amount: amount, currency: currency, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(width: 6),
                    Text('${(percentage * 100).round()}%', style: GoogleFonts.inter(fontSize: 10, color: muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(height: 4, decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(2))),
                    FractionallySizedBox(widthFactor: percentage.clamp(0.0, 1.0), child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
