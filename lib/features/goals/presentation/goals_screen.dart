import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../domain/goal_model.dart';
import '../providers/goals_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Formatter
// ─────────────────────────────────────────────────────────────────────────────
final _fmt =
    NumberFormat.currency(locale: 'es', symbol: 'RD\$', decimalDigits: 0);

String _f(double v) => _fmt.format(v);

// ─────────────────────────────────────────────────────────────────────────────
//  GoalsScreen
// ─────────────────────────────────────────────────────────────────────────────
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final textPrimary = isDark
        ? const Color(0xFFE8EEFF)
        : const Color(0xFF1A1F36);
    final surface =
        isDark ? const Color(0xFF0F1320) : const Color(0xFFFFFFFF);

    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas de ahorro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/goals/add'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/goals/add'),
        backgroundColor: const Color(0xFF3B5BDB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Agregar',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: goalsAsync.when(
        loading: () => _GoalsSkeleton(isDark: isDark, c: c),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40, color: c.expense),
              const SizedBox(height: 12),
              Text(
                'Error al cargar metas',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(goalsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 56,
                    color: c.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin metas activas',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea tu primera meta de ahorro',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            );
          }

          final totalSaved =
              goals.fold<double>(0, (s, g) => s + g.currentAmount);
          final activeCount = goals.where((g) => !g.isCompleted).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary card ──────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D1227)
                        : const Color(0xFFEEF2FF),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFC7D2FE),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL AHORRADO',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _f(totalSaved),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFC7D2FE)
                              : const Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'en $activeCount ${activeCount == 1 ? 'meta activa' : 'metas activas'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Section title ─────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: Text(
                    'Mis metas',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),

                // ── Goal list ─────────────────────────────────────────────
                ...goals.map(
                  (goal) => _GoalCard(
                    goal: goal,
                    isDark: isDark,
                    c: c,
                    surface: surface,
                    textPrimary: textPrimary,
                    onRemove: () async {
                      await ref
                          .read(goalNotifierProvider.notifier)
                          .remove(goal.id);
                    },
                  ),
                ),

                // ── Add new card ──────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push('/goals/add'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: c.muted.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Color(0xFF3B5BDB),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nueva meta',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3B5BDB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _GoalCard
// ─────────────────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final SavingGoal goal;
  final bool isDark;
  final FinPaColors c;
  final Color surface;
  final Color textPrimary;
  final VoidCallback onRemove;

  const _GoalCard({
    required this.goal,
    required this.isDark,
    required this.c,
    required this.surface,
    required this.textPrimary,
    required this.onRemove,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text(
            '¿Deseas eliminar la meta "${goal.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: c.expense),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = goal.deadline != null
        ? DateFormat('dd/MM/yyyy').format(goal.deadline!)
        : null;

    return GestureDetector(
      onTap: () => context.push('/goals/${goal.id}'),
      onLongPress: () => _confirmDelete(context),
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      if (dateLabel != null)
                        Text(
                          'Fecha límite: $dateLabel',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: c.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: goal.progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: c.cardBg),
                  FractionallySizedBox(
                    widthFactor: goal.progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goal.progressColor.withValues(alpha: 0.7),
                            goal.progressColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _f(goal.currentAmount),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  ' / ${_f(goal.targetAmount)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: c.muted),
                ),
                const Spacer(),
                if (!goal.isCompleted)
                  Text(
                    'Faltan ${_f(goal.remaining)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: goal.progressColor,
                    ),
                  ),
                if (goal.isCompleted)
                  Text(
                    '¡Meta alcanzada! 🎉',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.income,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton
// ─────────────────────────────────────────────────────────────────────────────
class _GoalsSkeleton extends StatefulWidget {
  final bool isDark;
  final FinPaColors c;

  const _GoalsSkeleton({required this.isDark, required this.c});

  @override
  State<_GoalsSkeleton> createState() => _GoalsSkeletonState();
}

class _GoalsSkeletonState extends State<_GoalsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final base = widget.c.cardBg.withValues(alpha: _anim.value);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary skeleton
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                height: 100,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              _SkeletonCard(base: base),
              _SkeletonCard(base: base),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Color base;

  const _SkeletonCard({required this.base});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: base.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 12,
                        width: 120,
                        color:
                            base.withValues(alpha: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                        height: 9,
                        width: 80,
                        color:
                            base.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
              height: 6,
              decoration: BoxDecoration(
                  color: base.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Container(
              height: 9,
              width: 160,
              color: base.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
