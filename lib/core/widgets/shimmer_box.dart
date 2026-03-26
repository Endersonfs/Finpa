import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ShimmerBox — caja de carga animada (shimmer)
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
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
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor =
        isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0);
    final highlightColor =
        isDark ? const Color(0xFF2A3A5C) : const Color(0xFFF0F2F8);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final color = Color.lerp(baseColor, highlightColor, _anim.value)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers de shimmer predefinidos
// ─────────────────────────────────────────────────────────────────────────────

/// Shimmer para una fila de transacción (icon + líneas de texto)
class TransactionTileShimmer extends StatelessWidget {
  const TransactionTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 13,
                  radius: 6,
                ),
                const SizedBox(height: 6),
                const ShimmerBox(width: 80, height: 10, radius: 5),
              ],
            ),
          ),
          const ShimmerBox(width: 70, height: 14, radius: 6),
        ],
      ),
    );
  }
}

/// Shimmer para BalanceCard
class BalanceCardShimmer extends StatelessWidget {
  const BalanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ShimmerBox(
        width: double.infinity,
        height: 160,
        radius: 20,
      ),
    );
  }
}

/// Shimmer para GoalCard
class GoalCardShimmer extends StatelessWidget {
  const GoalCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ShimmerBox(
        width: double.infinity,
        height: 120,
        radius: 16,
      ),
    );
  }
}

/// Shimmer para BudgetItem
class BudgetItemShimmer extends StatelessWidget {
  const BudgetItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ShimmerBox(
        width: double.infinity,
        height: 82,
        radius: 14,
      ),
    );
  }
}
