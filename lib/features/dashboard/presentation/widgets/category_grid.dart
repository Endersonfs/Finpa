import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/language_provider.dart';

// Metadata de cada categoría del dashboard
class _Cat {
  final String labelKey;
  final Color color;
  const _Cat(this.labelKey, this.color);
}

const _kCategories = <String, _Cat>{
  'food':          _Cat('categories.food',          Color(0xFFDC2626)),
  'transport':     _Cat('categories.transport',     Color(0xFF2563EB)),
  'entertainment': _Cat('categories.entertainment', Color(0xFF7C3AED)),
  'services':      _Cat('categories.services',      Color(0xFF059669)),
  'health':        _Cat('categories.health',        Color(0xFF0891B2)),
  'other':         _Cat('categories.other',         Color(0xFF8892B0)),
};

class CategoryGrid extends ConsumerWidget {
  /// null mientras carga — muestra skeleton
  final Map<String, double>? expenses;
  final AppCurrency? currency;

  const CategoryGrid({super.key, this.expenses, this.currency});

  void _showAmountDetail(BuildContext context, WidgetRef ref, String label, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(amount, currency: currency),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F7155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ref.tr('goals.exact_amount'),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ref.tr('common.close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses == null) return _CategorySkeleton();

    // Ordenar por monto desc y tomar hasta 6
    final sorted = expenses!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final items = sorted.take(6).toList();
    final maxAmount = items.isEmpty ? 1.0 : items.first.value;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final entry = items[i];
        final meta = _kCategories[entry.key] ??
            const _Cat('categories.other', Color(0xFF8892B0));
        final label = ref.tr(meta.labelKey);
        return _CategoryCard(
          label: label,
          color: meta.color,
          amount: CurrencyFormatter.formatCompact(entry.value, currency: currency),
          progress: (maxAmount > 0) ? entry.value / maxAmount : 0,
          onTapAmount: () => _showAmountDetail(context, ref, label, entry.value),
        );
      },
    );
  }
}

// ── Tarjeta de categoría ────────────────────────
class _CategoryCard extends StatelessWidget {
  final String label;
  final Color color;
  final String amount;
  final double progress; // 0.0–1.0
  final VoidCallback onTapAmount;

  const _CategoryCard({
    required this.label,
    required this.color,
    required this.amount,
    required this.progress,
    required this.onTapAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0F1320) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);
    final textPrimary   = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary = isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot + Nombre
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Monto
                  GestureDetector(
                    onTap: onTapAmount,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Barra de progreso (2px al fondo)
          Stack(
            children: [
              Container(height: 6, color: border),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(height: 6, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton (cargando) ─────────────────────────
class _CategorySkeleton extends StatefulWidget {
  @override
  State<_CategorySkeleton> createState() => _CategorySkeletonState();
}

class _CategorySkeletonState extends State<_CategorySkeleton>
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
        final opacity = 0.4 + _ctrl.value * 0.4;
        final color = (isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0))
            .withOpacity(opacity);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
