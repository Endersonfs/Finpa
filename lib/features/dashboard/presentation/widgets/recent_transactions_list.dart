import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../transactions/domain/transaction.dart';

// Emoji + color por categoría
class _CatDisplay {
  final String emoji;
  final Color bg;
  const _CatDisplay(this.emoji, this.bg);
}

const _kDisplay = <String, _CatDisplay>{
  'food':          _CatDisplay('🍔', Color(0xFFFFEEEE)),
  'transport':     _CatDisplay('🚗', Color(0xFFEEF2FF)),
  'entertainment': _CatDisplay('🎬', Color(0xFFF3F0FF)),
  'services':      _CatDisplay('💡', Color(0xFFECFDF5)),
  'health':        _CatDisplay('💊', Color(0xFFEFF6FF)),
  'salary':        _CatDisplay('💰', Color(0xFFECFDF5)),
  'freelance':     _CatDisplay('💻', Color(0xFFEEF2FF)),
  'shopping':      _CatDisplay('🛍️', Color(0xFFFFF7ED)),
  'investment':    _CatDisplay('📈', Color(0xFFF0FDF4)),
  'gift':          _CatDisplay('🎁', Color(0xFFFDF4FF)),
};

const _kDisplayDark = <String, _CatDisplay>{
  'food':          _CatDisplay('🍔', Color(0xFF2D1515)),
  'transport':     _CatDisplay('🚗', Color(0xFF1A2040)),
  'entertainment': _CatDisplay('🎬', Color(0xFF1E1535)),
  'services':      _CatDisplay('💡', Color(0xFF0D2820)),
  'health':        _CatDisplay('💊', Color(0xFF0D1E30)),
  'salary':        _CatDisplay('💰', Color(0xFF0D2820)),
  'freelance':     _CatDisplay('💻', Color(0xFF1A2040)),
  'shopping':      _CatDisplay('🛍️', Color(0xFF2D1D0D)),
  'investment':    _CatDisplay('📈', Color(0xFF0D2010)),
  'gift':          _CatDisplay('🎁', Color(0xFF231535)),
};

class RecentTransactionsList extends StatelessWidget {
  final List<Transaction>? transactions;

  const RecentTransactionsList({super.key, this.transactions});

  static final _moneyFmt = NumberFormat.currency(
    locale: 'es',
    symbol: 'Bs.',
    decimalDigits: 0,
  );

  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (transactions == null) return _TransactionSkeleton();

    if (transactions!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Sin transacciones este mes',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8892B0) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...transactions!.map((t) => _TransactionTile(
              transaction: t,
              isDark: isDark,
              moneyFmt: _moneyFmt,
              timeFmt: _timeFmt,
            )),
        // Ver todos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => context.push('/transactions'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                'Ver todos los movimientos →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F7155),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tile individual ─────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  final NumberFormat moneyFmt;
  final DateFormat timeFmt;

  const _TransactionTile({
    required this.transaction,
    required this.isDark,
    required this.moneyFmt,
    required this.timeFmt,
  });

  @override
  Widget build(BuildContext context) {
    final display = (isDark
            ? _kDisplayDark[transaction.category]
            : _kDisplay[transaction.category]) ??
        _CatDisplay('📊', isDark ? const Color(0xFF1E2840) : const Color(0xFFF0F2F8));

    final amountColor = transaction.isIncome
        ? const Color(0xFF059669) // light income
        : const Color(0xFFDC2626); // light expense

    final amountColorDark = transaction.isIncome
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);

    final textPrimary   = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary = isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Emoji + bg
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: display.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(display.emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre + categoría · hora
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? transaction.category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_categoryLabel(transaction.category)} · ${timeFmt.format(transaction.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Monto
            Text(
              '${transaction.isIncome ? '+' : '-'}${moneyFmt.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? amountColorDark : amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryLabel(String id) {
    const labels = {
      'food': 'Comida', 'transport': 'Transporte',
      'entertainment': 'Entretenimiento', 'services': 'Servicios',
      'health': 'Salud', 'salary': 'Salario',
      'freelance': 'Freelance', 'shopping': 'Compras',
      'investment': 'Inversión', 'gift': 'Regalo',
    };
    return labels[id] ?? 'Otros';
  }
}

// ── Skeleton ────────────────────────────────────
class _TransactionSkeleton extends StatefulWidget {
  @override
  State<_TransactionSkeleton> createState() => _TransactionSkeletonState();
}

class _TransactionSkeletonState extends State<_TransactionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final color = (isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0))
            .withOpacity(0.5 + _ctrl.value * 0.4);
        return Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 5),
                        Container(height: 10, width: 80, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                  Container(height: 12, width: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

