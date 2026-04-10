import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinPaCard — card base con border y radius consistentes
// ─────────────────────────────────────────────────────────────────────────────

class FinPaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  const FinPaCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.radius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final bg = color ?? Theme.of(context).colorScheme.surface;
    final border = borderColor ?? c.border;

    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

