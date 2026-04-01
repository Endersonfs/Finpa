import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/transaction.dart';
import '../providers/transaction_provider.dart';

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

// ── Formato de moneda ─────────────────────────────────────────────────────────

final _currencyFmt = NumberFormat.currency(
  locale: 'es',
  symbol: 'RD\$',
  decimalDigits: 0,
);

// ── Screen ────────────────────────────────────────────────────────────────────

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

  String _dateHeader(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Hoy';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ayer';
    }
    return DateFormat('d MMM', 'es').format(date);
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
    // Orden pila: primero por fecha de transacción desc,
    // luego por cuándo se registró desc (última ingresada arriba).
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  // Agrupa la lista en un mapa ordenado: dateKey → List<Transaction>
  Map<String, List<Transaction>> _groupByDate(List<Transaction> list) {
    final map = <String, List<Transaction>>{};
    for (final t in list) {
      final key = _dateHeader(t.date);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(c, cs, isDark),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showSearch) _SearchBar(controller: _searchCtrl, onChanged: (v) => setState(() => _search = v)),
          _FilterChips(
            current: _filter,
            onChanged: (v) => setState(() => _filter = v),
            c: c,
            cs: cs,
          ),
          _SummaryCards(c: c, cs: cs),
          const SizedBox(height: 8),
          Expanded(child: _TransactionList(
            filter: _filter,
            search: _search,
            applyFilters: _applyFilters,
            groupByDate: _groupByDate,
            c: c,
            cs: cs,
            isDark: isDark,
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: const Color(0xFF3B5BDB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Agregar',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  AppBar _buildAppBar(FinPaColors c, ColorScheme cs, bool isDark) {
    return AppBar(
      title: Text(
        'Movimientos',
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
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => _showFilterSheet(context, c, cs),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, FinPaColors c, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filtros avanzados',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El filtro por rango de fechas estara disponible proximamente.',
              style: GoogleFonts.inter(color: c.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

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
          hintText: 'Buscar transacciones...',
          prefixIcon: Icon(Icons.search, color: c.muted, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final TransactionType? current;
  final ValueChanged<TransactionType?> onChanged;
  final FinPaColors c;
  final ColorScheme cs;

  const _FilterChips({
    required this.current,
    required this.onChanged,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'Todo',
            active: current == null,
            onTap: () => onChanged(null),
            c: c,
            cs: cs,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Ingresos',
            active: current == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
            c: c,
            cs: cs,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Gastos',
            active: current == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
            c: c,
            cs: cs,
          ),
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

  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B5BDB) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: c.border),
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

// ── Summary cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends ConsumerWidget {
  final FinPaColors c;
  final ColorScheme cs;

  const _SummaryCards({required this.c, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final data = summaryAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Ingresos',
              amount: data?['income'],
              icon: Icons.arrow_upward_rounded,
              color: c.income,
              c: c,
              cs: cs,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'Gastos',
              amount: data?['expense'],
              icon: Icons.arrow_downward_rounded,
              color: c.expense,
              c: c,
              cs: cs,
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

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = amount == null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: c.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (isLoading)
                  _SkeletonBox(width: 60, height: 12, radius: 4)
                else
                  Text(
                    _currencyFmt.format(amount),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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

// ── Transaction list ──────────────────────────────────────────────────────────

class _TransactionList extends ConsumerWidget {
  final TransactionType? filter;
  final String search;
  final List<Transaction> Function(List<Transaction>) applyFilters;
  final Map<String, List<Transaction>> Function(List<Transaction>) groupByDate;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;

  const _TransactionList({
    required this.filter,
    required this.search,
    required this.applyFilters,
    required this.groupByDate,
    required this.c,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);

    return txAsync.when(
      loading: () => _LoadingList(c: c, cs: cs),
      error: (e, _) => _ErrorState(error: e.toString(), onRetry: () => ref.invalidate(transactionsProvider)),
      data: (all) {
        final filtered = applyFilters(all);
        if (filtered.isEmpty) {
          return _EmptyState(c: c, cs: cs);
        }
        final groups = groupByDate(filtered);
        final keys = groups.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: keys.fold<int>(0, (sum, k) => sum + 1 + (groups[k]?.length ?? 0)),
          itemBuilder: (context, index) {
            // Flatten groups into a single list of headers + items
            int cursor = 0;
            for (final key in keys) {
              final items = groups[key]!;
              if (index == cursor) {
                // Header
                return _DateHeader(label: key, c: c, cs: cs);
              }
              cursor++;
              if (index < cursor + items.length) {
                final tx = items[index - cursor];
                return _TransactionTile(
                  transaction: tx,
                  c: c,
                  cs: cs,
                  isDark: isDark,
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

// ── Date header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  final FinPaColors c;
  final ColorScheme cs;

  const _DateHeader({required this.label, required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.muted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;

  const _TransactionTile({
    required this.transaction,
    required this.c,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final emoji = _kEmoji[t.category] ?? '📊';
    final bgMap = isDark ? _kBgDark : _kBgLight;
    final emojiBoxBg = bgMap[t.category] ?? (isDark ? _kFallbackBgDark : _kFallbackBgLight);
    final amountColor = t.isIncome ? c.income : c.expense;
    final prefix = t.isIncome ? '+' : '-';
    final timeStr = DateFormat('HH:mm').format(t.date);
    final label = t.description?.isNotEmpty == true
        ? t.description!
        : _categoryLabel(t.category);

    return GestureDetector(
      onTap: () => context.push('/transactions/${t.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            // Emoji box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: emojiBoxBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            // Description & category·time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_categoryLabel(t.category)} · $timeStr',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '$prefix${_currencyFmt.format(t.amount)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String cat) {
    const labels = <String, String>{
      'food': 'Comida',
      'transport': 'Transporte',
      'entertainment': 'Entretenimiento',
      'services': 'Servicios',
      'health': 'Salud',
      'salary': 'Salario',
      'freelance': 'Freelance',
      'shopping': 'Compras',
      'investment': 'Inversion',
      'gift': 'Regalo',
      'education': 'Educacion',
      'housing': 'Hogar',
      'clothing': 'Ropa',
      'business': 'Negocio',
      'other': 'Otros',
    };
    return labels[cat] ?? cat;
  }
}

// ── Skeleton list (loading) ───────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  final FinPaColors c;
  final ColorScheme cs;

  const _LoadingList({required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 5,
      itemBuilder: (context, i) => _TileSkeleton(c: c, cs: cs),
    );
  }
}

class _TileSkeleton extends StatefulWidget {
  final FinPaColors c;
  final ColorScheme cs;

  const _TileSkeleton({required this.c, required this.cs});

  @override
  State<_TileSkeleton> createState() => _TileSkeletonState();
}

class _TileSkeletonState extends State<_TileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final cs = widget.cs;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              _SkeletonBox(width: 40, height: 40, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 120, height: 12, radius: 4),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 80, height: 10, radius: 4),
                  ],
                ),
              ),
              _SkeletonBox(width: 64, height: 12, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton box ──────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: c.expense),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar las transacciones',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: c.muted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final FinPaColors c;
  final ColorScheme cs;

  const _EmptyState({required this.c, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: c.muted,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin transacciones',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega tu primera transaccion con el boton +',
            style: GoogleFonts.inter(fontSize: 13, color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
