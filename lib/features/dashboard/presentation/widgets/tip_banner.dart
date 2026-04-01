import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_provider.dart';

class TipBanner extends ConsumerWidget {
  const TipBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(aiTipProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: tipAsync.when(
        loading: () => _TipShimmer(isDark: isDark),
        error: (_, __) => const SizedBox.shrink(),
        data: (tip) => _TipContent(tip: tip, isDark: isDark),
      ),
    );
  }
}

// ── Contenido del tip ───────────────────────────
class _TipContent extends StatelessWidget {
  final String tip;
  final bool isDark;

  const _TipContent({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg         = isDark ? const Color(0xFF0F1320) : const Color(0xFFEEF2FF);
    final borderCol  = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFC7D2FE);
    final textColor  = isDark ? const Color(0xFF93C5FD) : const Color(0xFF3730A3);

    return GestureDetector(
      onTap: () => context.push('/chat'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Punto azul
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF3B5BDB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            // Texto tip
            Expanded(
              child: Text(
                tip,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: textColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer mientras carga ───────────────────────
class _TipShimmer extends StatefulWidget {
  final bool isDark;
  const _TipShimmer({required this.isDark});

  @override
  State<_TipShimmer> createState() => _TipShimmerState();
}

class _TipShimmerState extends State<_TipShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 3).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg        = widget.isDark ? const Color(0xFF0F1320) : const Color(0xFFEEF2FF);
    final border    = widget.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFC7D2FE);
    final baseShimmer  = widget.isDark ? const Color(0xFF1A2540) : const Color(0xFFDDE4FF);
    final highlight = widget.isDark ? const Color(0xFF253560) : const Color(0xFFF0F3FF);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_anim.value, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: [baseShimmer, highlight, baseShimmer],
            ),
          ),
        ),
      ),
    );
  }
}
