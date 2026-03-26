import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/reports_provider.dart';

// ─── Constantes de categoría ───────────────────────────────────────────────

const _months = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const _catColors = {
  'food': Color(0xFFDC2626),
  'transport': Color(0xFF2563EB),
  'entertainment': Color(0xFF7C3AED),
  'health': Color(0xFF0891B2),
  'services': Color(0xFF059669),
  'salary': Color(0xFF059669),
  'freelance': Color(0xFF2563EB),
  'shopping': Color(0xFFF59E0B),
  'other': Color(0xFF8892B0),
};

const _catLabels = {
  'food': 'Comida',
  'transport': 'Transporte',
  'entertainment': 'Entretenimiento',
  'health': 'Salud',
  'services': 'Servicios',
  'salary': 'Salario',
  'freelance': 'Freelance',
  'shopping': 'Compras',
  'investment': 'Inversión',
  'gift': 'Regalos',
  'education': 'Educación',
  'housing': 'Vivienda',
  'clothing': 'Ropa',
  'business': 'Negocio',
  'other': 'Otros',
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
  'other': '📊',
};

// ─── Formateador de moneda ─────────────────────────────────────────────────

final _fmt = NumberFormat.currency(locale: 'es', symbol: 'RD\$', decimalDigits: 0);

String _fmtAmount(double v) => _fmt.format(v);

// ─── ReportsScreen ─────────────────────────────────────────────────────────

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
    final textPrimary = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final muted = c.muted;

    final reportsAsync = ref.watch(
      reportsProvider((month: _selectedMonth, year: _selectedYear)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList.list(
              children: [
                // ── Selector de período ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Mes', label: Text('Mes')),
                      ButtonSegment(value: 'Año', label: Text('Año')),
                    ],
                    selected: {_period},
                    onSelectionChanged: (s) =>
                        setState(() => _period = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF3B5BDB)
                            : Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? Colors.white
                            : muted,
                      ),
                    ),
                  ),
                ),

                // ── Selector de mes (solo si período = 'Mes') ────────────
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
                          onTap: () =>
                              setState(() => _selectedMonth = index + 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3B5BDB)
                                  : surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3B5BDB)
                                    : c.border,
                              ),
                            ),
                            child: Text(
                              _months[index],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : muted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // ── Contenido (loading / error / data) ───────────────────
                reportsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B5BDB),
                      ),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'Error al cargar datos',
                        style: GoogleFonts.inter(color: c.expense),
                      ),
                    ),
                  ),
                  data: (data) => _ReportsContent(
                    data: data,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    surface: surface,
                    muted: muted,
                    border: c.border,
                    cardBg: c.cardBg,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    touchedBarIndex: _touchedBarIndex,
                    touchedPieIndex: _touchedPieIndex,
                    onBarTouch: (i) => setState(() => _touchedBarIndex = i),
                    onPieTouch: (i) => setState(() => _touchedPieIndex = i),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cuántos meses mostrar: si es el año actual, solo hasta el mes actual.
  int _availableMonths() {
    final now = DateTime.now();
    if (_selectedYear == now.year) return now.month;
    return 12;
  }
}

// ─── Widget de contenido de reportes ──────────────────────────────────────

class _ReportsContent extends StatelessWidget {
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
  });

  final ReportData data;
  final bool isDark;
  final Color textPrimary;
  final Color surface;
  final Color muted;
  final Color border;
  final Color cardBg;
  final int selectedMonth;
  final int selectedYear;
  final int touchedBarIndex;
  final int touchedPieIndex;
  final ValueChanged<int> onBarTouch;
  final ValueChanged<int> onPieTouch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBarCard(context),
        _buildDonutCard(context),
        _buildLineCard(context),
        _buildTopExpensesCard(context),
      ],
    );
  }

  // ─── Card 1: Barras — Gastos por mes ──────────────────────────────────────

  Widget _buildBarCard(BuildContext context) {
    final maxExpense = data.last6Months
        .map((e) => e.expense)
        .fold(0.0, (a, b) => a > b ? a : b);

    final gridLineColor =
        isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por mes',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Últimos 6 meses',
            style: GoogleFonts.inter(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxExpense > 0 ? maxExpense * 1.2 : 100,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    onBarTouch(
                      response?.spot?.touchedBarGroupIndex ?? -1,
                    );
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF3B5BDB),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      'RD\$${NumberFormat.compactCurrency(locale: 'es', symbol: '', decimalDigits: 0).format(rod.toY)}',
                      GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                        if (idx < 0 || idx >= data.last6Months.length) {
                          return const SizedBox.shrink();
                        }
                        final m = data.last6Months[idx].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _months[m - 1],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridLineColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.last6Months.asMap().entries.map((entry) {
                  final isSelected = entry.key == touchedBarIndex ||
                      (entry.value.month == selectedMonth &&
                          entry.value.year == selectedYear);
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.expense,
                        color: isSelected
                            ? const Color(0xFF3B5BDB)
                            : (isDark
                                ? const Color(0xFF1E2840)
                                : const Color(0xFFE2E6F0)),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
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

  // ─── Card 2: Donut — Distribución por categoría ───────────────────────────

  Widget _buildDonutCard(BuildContext context) {
    final categoryExpenses = data.categoryExpenses;
    final totalExpense =
        categoryExpenses.values.fold(0.0, (a, b) => a + b);

    final entries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieSections = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value.key;
      final amount = entry.value.value;
      final isTouched = i == touchedPieIndex;

      return PieChartSectionData(
        value: amount,
        color: _catColors[cat] ?? const Color(0xFF8892B0),
        radius: isTouched ? 38 : 32,
        showTitle: false,
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de gastos',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Este mes',
            style: GoogleFonts.inter(fontSize: 10, color: muted),
          ),
          const SizedBox(height: 16),
          if (categoryExpenses.isEmpty)
            Center(
              child: Text(
                'Sin datos',
                style: GoogleFonts.inter(color: muted),
              ),
            )
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
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              onPieTouch(
                                response?.touchedSection
                                        ?.touchedSectionIndex ??
                                    -1,
                              );
                            },
                          ),
                          sections: pieSections,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: muted,
                            ),
                          ),
                          Text(
                            'RD\$${NumberFormat.compactCurrency(locale: 'es', symbol: '', decimalDigits: 0).format(totalExpense)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _PieLegend(
                    entries: entries,
                    totalExpense: totalExpense,
                    textPrimary: textPrimary,
                    muted: muted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Card 3: Línea — Ingreso vs Gasto ─────────────────────────────────────

  Widget _buildLineCard(BuildContext context) {
    final allValues = data.last6Months
        .expand((e) => [e.income, e.expense])
        .toList();
    final maxValue =
        allValues.fold(0.0, (a, b) => a > b ? a : b);

    final gridLineColor =
        isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);
    final tooltipBg =
        isDark ? const Color(0xFF141928) : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingreso vs Gasto',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _LegendDot(color: const Color(0xFF059669)),
              const SizedBox(width: 4),
              Text(
                'Ingresos',
                style: GoogleFonts.inter(fontSize: 11, color: muted),
              ),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFDC2626)),
              const SizedBox(width: 4),
              Text(
                'Gastos',
                style: GoogleFonts.inter(fontSize: 11, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => tooltipBg,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        _fmtAmount(spot.y),
                        GoogleFonts.inter(
                          color: isIncome
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.last6Months.length) {
                          return const SizedBox.shrink();
                        }
                        final m = data.last6Months[idx].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _months[m - 1],
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: gridLineColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Línea verde (income)
                  LineChartBarData(
                    spots: data.last6Months
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.income))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF059669),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFF059669),
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF059669).withValues(alpha: 20),
                    ),
                  ),
                  // Línea roja (expense)
                  LineChartBarData(
                    spots: data.last6Months
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.expense))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFFDC2626),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFFDC2626),
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFDC2626).withValues(alpha: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card 4: Top 5 gastos del mes ─────────────────────────────────────────

  Widget _buildTopExpensesCard(BuildContext context) {
    final categoryExpenses = data.categoryExpenses;
    final totalExpense =
        categoryExpenses.values.fold(0.0, (a, b) => a + b);

    final sorted = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top gastos del mes',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            Center(
              child: Text(
                'Sin datos',
                style: GoogleFonts.inter(color: muted),
              ),
            )
          else
            ...top5.map(
              (entry) => _TopCategoryRow(
                emoji: _catEmojis[entry.key] ?? '📊',
                label: _catLabels[entry.key] ?? entry.key,
                amount: entry.value,
                percentage:
                    totalExpense > 0 ? entry.value / totalExpense : 0,
                color: _catColors[entry.key] ?? const Color(0xFF8892B0),
                textPrimary: textPrimary,
                muted: muted,
                cardBg: cardBg,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── _PieLegend ────────────────────────────────────────────────────────────

class _PieLegend extends StatelessWidget {
  const _PieLegend({
    required this.entries,
    required this.totalExpense,
    required this.textPrimary,
    required this.muted,
  });

  final List<MapEntry<String, double>> entries;
  final double totalExpense;
  final Color textPrimary;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.take(6).map((entry) {
        final cat = entry.key;
        final amount = entry.value;
        final pct = totalExpense > 0 ? amount / totalExpense : 0.0;
        final catColor = _catColors[cat] ?? const Color(0xFF8892B0);
        final catLabel = _catLabels[cat] ?? cat;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  catLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── _TopCategoryRow ───────────────────────────────────────────────────────

class _TopCategoryRow extends StatelessWidget {
  const _TopCategoryRow({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.textPrimary,
    required this.muted,
    required this.cardBg,
  });

  final String emoji;
  final String label;
  final double amount;
  final double percentage;
  final Color color;
  final Color textPrimary;
  final Color muted;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    final pct = percentage.clamp(0.0, 1.0);

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
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fmtAmount(amount),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
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

// ─── _LegendDot ────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
