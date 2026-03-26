import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../domain/module_model.dart';
import '../providers/education_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EducationScreen
// ─────────────────────────────────────────────────────────────────────────────

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = theme.extension<FinPaColors>()!;
    final textPrimary = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Educación financiera'),
      ),
      body: modulesAsync.when(
        loading: () => _EducationSkeleton(isDark: isDark, c: c),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: c.muted,
              ),
              const SizedBox(height: 12),
              Text(
                'Error al cargar el contenido',
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(modulesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (modules) {
          if (modules.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 56,
                    color: c.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay contenido disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            );
          }

          final totalLessons =
              modules.fold<int>(0, (sum, m) => sum + m.totalCount);
          final totalCompleted =
              modules.fold<int>(0, (sum, m) => sum + m.completedCount);
          final globalProgress =
              totalLessons > 0 ? totalCompleted / totalLessons : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tarjeta progreso general ──────────────────────────────
                _ProgressCard(
                  isDark: isDark,
                  totalCompleted: totalCompleted,
                  totalLessons: totalLessons,
                  globalProgress: globalProgress,
                ),

                // ── Título Módulos ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: Text(
                    'Módulos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),

                // ── Lista de módulos ─────────────────────────────────────
                const SizedBox(height: 8),
                ...modules.map(
                  (module) => _ModuleCard(module: module, isDark: isDark, c: c),
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
//  _ProgressCard
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final bool isDark;
  final int totalCompleted;
  final int totalLessons;
  final double globalProgress;

  const _ProgressCard({
    required this.isDark,
    required this.totalCompleted,
    required this.totalLessons,
    required this.globalProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1227) : const Color(0xFFEEF2FF),
        border: Border.all(
          color:
              isDark ? const Color(0xFF1E3A8A) : const Color(0xFFC7D2FE),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tu progreso',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFC7D2FE)
                        : const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Text(
                '$totalCompleted de $totalLessons lecciones',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    color: isDark
                        ? const Color(0xFF1E2840)
                        : const Color(0xFFE0E7FF),
                  ),
                  FractionallySizedBox(
                    widthFactor: globalProgress.clamp(0.0, 1.0),
                    child: Container(color: const Color(0xFF3B5BDB)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(globalProgress * 100).round()}% completado',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ModuleCard
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final bool isDark;
  final FinPaColors c;

  const _ModuleCard({
    required this.module,
    required this.isDark,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);

    final borderColor = module.isCompleted
        ? const Color(0xFF059669)
        : module.progress > 0
            ? const Color(0xFF3B5BDB)
            : c.border;

    final borderWidth =
        module.progress > 0 && !module.isCompleted ? 1.5 : 1.0;

    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Emoji en círculo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.cardBg,
            ),
            child: Center(
              child: Text(
                module.iconEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (module.isCompleted)
                      _Badge('Completado', const Color(0xFF059669))
                    else if (module.progress > 0)
                      _Badge('En progreso', const Color(0xFF3B5BDB))
                    else if (!module.isUnlocked)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: c.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bloqueado',
                            style: TextStyle(fontSize: 10, color: c.muted),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${module.completedCount}/${module.totalCount} lecciones',
                  style: TextStyle(fontSize: 10, color: c.muted),
                ),
                if (module.progress > 0 && !module.isCompleted) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        children: [
                          Container(color: c.cardBg),
                          FractionallySizedBox(
                            widthFactor: module.progress.clamp(0.0, 1.0),
                            child: Container(color: module.progressColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (module.isUnlocked)
            Icon(Icons.chevron_right_rounded, color: c.muted),
        ],
      ),
    );

    if (!module.isUnlocked) {
      card = Opacity(opacity: 0.5, child: card);
      return card;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ModuleLessonsScreen(module: module),
          ),
        );
      },
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _Badge
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ModuleLessonsScreen
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleLessonsScreen extends ConsumerWidget {
  final ModuleModel module;

  const _ModuleLessonsScreen({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener el módulo actualizado del provider para reflejar cambios de progreso
    final modulesAsync = ref.watch(modulesProvider);
    final updatedModule = modulesAsync.valueOrNull
            ?.where((m) => m.id == module.id)
            .firstOrNull ??
        module;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = theme.extension<FinPaColors>()!;
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);

    return Scaffold(
      appBar: AppBar(
        title: Text('${updatedModule.iconEmoji} ${updatedModule.title}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: updatedModule.lessons.length,
        itemBuilder: (context, i) {
          final lesson = updatedModule.lessons[i];
          final isCompleted =
              updatedModule.completedLessonIds.contains(lesson.id);

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isCompleted ? const Color(0xFF059669) : c.muted,
              size: 24,
            ),
            title: Text(
              lesson.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              'Lección ${i + 1} de ${updatedModule.totalCount}',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            trailing: isCompleted
                ? null
                : Icon(
                    Icons.chevron_right_rounded,
                    color: c.muted,
                  ),
            onTap: () => context.push('/education/${lesson.id}'),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _EducationSkeleton
// ─────────────────────────────────────────────────────────────────────────────

class _EducationSkeleton extends StatefulWidget {
  final bool isDark;
  final FinPaColors c;

  const _EducationSkeleton({required this.isDark, required this.c});

  @override
  State<_EducationSkeleton> createState() => _EducationSkeletonState();
}

class _EducationSkeletonState extends State<_EducationSkeleton>
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
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final shimmerColor = (widget.isDark
                ? const Color(0xFF1E2840)
                : const Color(0xFFE2E6F0))
            .withValues(alpha: _anim.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton tarjeta progreso
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                height: 100,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              // Skeleton título
              Container(
                margin: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                height: 18,
                width: 80,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Skeleton 3 módulos
              for (int i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  height: 80,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
