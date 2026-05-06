import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/widgets/compact_amount_text.dart';

class BalanceCard extends ConsumerWidget {
  final double? income;
  final double? expense;
  final double? available;
  final double? saved;
  final AppCurrency? currency;

  const BalanceCard({
    super.key,
    this.income,
    this.expense,
    this.available,
    this.saved,
    this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = available ??
        ((income != null && expense != null) ? income! - expense! : null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2F7155),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.tr('dashboard.you_can_spend'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          balance == null
              ? const _Skeleton(width: 160, height: 32)
              : CompactAmountText(
                  amount: balance,
                  currency: currency,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
          if (saved != null && saved! > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '+ ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                CompactAmountText(
                  amount: saved!,
                  currency: currency,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                Text(
                  ' ${ref.tr('dashboard.saved_in_goals')}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          Row(
            children: [
              _Chip(
                label: ref.tr('dashboard.income'),
                amount: income,
                currency: currency,
                valueColor: const Color(0xFF6EE7B7),
              ),
              const SizedBox(width: 10),
              _Chip(
                label: ref.tr('dashboard.expense'),
                amount: expense,
                currency: currency,
                valueColor: const Color(0xFFFCA5A5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final double? amount;
  final AppCurrency? currency;
  final Color valueColor;

  const _Chip({
    required this.label,
    this.amount,
    this.currency,
    required this.valueColor,
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
        child: amount == null
            ? const _Skeleton(width: 60, height: 14)
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
                  CompactAmountText(
                    amount: amount!,
                    currency: currency,
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

class _Skeleton extends StatefulWidget {
  final double width;
  final double height;
  const _Skeleton({required this.width, required this.height});
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12 + _ctrl.value * 0.12), borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
