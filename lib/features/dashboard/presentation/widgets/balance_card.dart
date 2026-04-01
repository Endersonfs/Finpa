import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatelessWidget {
  final double? income;
  final double? expense;
  final double? available;
  final double? saved;

  const BalanceCard({super.key, this.income, this.expense, this.available, this.saved});

  static final _fmt = NumberFormat.currency(
    locale: 'es',
    symbol: 'RD\$',
    decimalDigits: 0,
  );

  String _format(double? v) => v == null ? '—' : _fmt.format(v);

  @override
  Widget build(BuildContext context) {
    final balance = available ??
        ((income != null && expense != null) ? income! - expense! : null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3B5BDB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Etiqueta ─────────────────────────
          Text(
            'PUEDES GASTAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // ── Monto principal ──────────────────
          balance == null
              ? _Skeleton(width: 160, height: 32)
              : Text(
                  _format(balance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
          if (saved != null && saved! > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${_format(saved!)} apartados en tus metas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── Chips ingresos / gastos ───────────
          Row(
            children: [
              _Chip(
                label: 'Ingresos',
                value: _format(income),
                valueColor: const Color(0xFF6EE7B7),
                loading: income == null,
              ),
              const SizedBox(width: 10),
              _Chip(
                label: 'Gastos',
                value: _format(expense),
                valueColor: const Color(0xFFFCA5A5),
                loading: expense == null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chip individual ─────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool loading;

  const _Chip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? _Skeleton(width: 60, height: 14)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Skeleton placeholder ────────────────────────
class _Skeleton extends StatefulWidget {
  final double width;
  final double height;

  const _Skeleton({required this.width, required this.height});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12 + _ctrl.value * 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
