import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../domain/lesson_model.dart';
import '../domain/module_model.dart';
import '../providers/education_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Quiz data
// ─────────────────────────────────────────────────────────────────────────────

class _Quiz {
  final String question;
  final List<String> options;
  final int correctIndex;

  const _Quiz(this.question, this.options, this.correctIndex);
}

const _kQuizzes = {
  'presupuesto': _Quiz(
    '¿Qué porcentaje sugiere la regla 50/30/20 para necesidades?',
    ['30%', '50%', '20%', '70%'],
    1,
  ),
  'ahorro': _Quiz(
    '¿Cuántos meses de gastos debe cubrir un fondo de emergencia?',
    ['1-2 meses', '3-6 meses', '12 meses', '2 semanas'],
    1,
  ),
  'deuda': _Quiz(
    'En la estrategia "Avalancha", ¿qué deuda pagas primero?',
    ['La más pequeña', 'La más antigua', 'La de mayor interés', 'La del banco'],
    2,
  ),
  'inversion': _Quiz(
    '¿Qué es el interés compuesto?',
    [
      'Interés sobre el capital original',
      'Interés sobre intereses acumulados',
      'Una tarifa bancaria',
      'Un tipo de deuda',
    ],
    1,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
//  LessonDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const LessonDetailScreen({super.key, required this.id});

  @override
  ConsumerState<LessonDetailScreen> createState() =>
      _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  int? _selectedAnswer;
  bool _answered = false;
  bool _isCompleting = false;

  // Resolved from providers
  LessonModel? _lesson;
  ModuleModel? _module;
  int _lessonIndex = 0;
  bool _isAlreadyCompleted = false;

  void _resolveLesson(List<ModuleModel> modules) {
    for (final mod in modules) {
      for (int i = 0; i < mod.lessons.length; i++) {
        if (mod.lessons[i].id == widget.id) {
          _lesson = mod.lessons[i];
          _module = mod;
          _lessonIndex = i;
          _isAlreadyCompleted =
              mod.completedLessonIds.contains(widget.id);
          return;
        }
      }
    }
  }

  Future<void> _complete() async {
    if (_lesson == null || _module == null) return;

    setState(() => _isCompleting = true);
    try {
      await ref
          .read(educationNotifierProvider.notifier)
          .markLessonComplete(_lesson!.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Lección completada! 🎓'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final isLastLesson = _lessonIndex == _module!.totalCount - 1;
      if (isLastLesson) {
        Navigator.pop(context);
      } else {
        final nextLesson = _module!.lessons[_lessonIndex + 1];
        // ignore: use_build_context_synchronously
        context.pushReplacement('/education/${nextLesson.id}');
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(modulesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = theme.extension<FinPaColors>()!;
    final surface = theme.colorScheme.surface;
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary =
        isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    return modulesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Lección')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Lección')),
        body: Center(
          child: Text(
            'Error al cargar la lección',
            style: TextStyle(color: c.muted),
          ),
        ),
      ),
      data: (modules) {
        _resolveLesson(modules);

        if (_lesson == null || _module == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lección')),
            body: Center(
              child: Text(
                'Lección no encontrada',
                style: TextStyle(color: c.muted),
              ),
            ),
          );
        }

        final lesson = _lesson!;
        final module = _module!;
        final lessonIndex = _lessonIndex;
        final isLastLesson = lessonIndex == module.totalCount - 1;
        final quiz = _kQuizzes[lesson.category];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Lección ${lessonIndex + 1} de ${module.totalCount}',
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Barra de progreso de lección ──────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 4,
                    child: Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                color: isDark
                                    ? const Color(0xFF1E2840)
                                    : const Color(0xFFE2E6F0),
                              ),
                              FractionallySizedBox(
                                widthFactor: ((lessonIndex + 1) /
                                        module.totalCount)
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  color: const Color(0xFF3B5BDB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Card de contenido ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Quiz ──────────────────────────────────────────────────
                if (quiz != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Pon a prueba lo que aprendiste',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quiz.question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opciones
                  ...List.generate(quiz.options.length, (i) {
                    final isSelected = _selectedAnswer == i;
                    final isCorrect = quiz.correctIndex == i;
                    final isWrong = _answered && isSelected && !isCorrect;
                    final showCorrect = _answered && isCorrect;

                    Color bgColor = surface;
                    Color borderColor = c.border;
                    if (showCorrect) {
                      bgColor = const Color(0xFFECFDF5);
                      borderColor = const Color(0xFF059669);
                    }
                    if (isWrong) {
                      bgColor = const Color(0xFFFEF2F2);
                      borderColor = const Color(0xFFDC2626);
                    }

                    // In dark mode adjust bg colors
                    if (isDark) {
                      if (showCorrect) {
                        bgColor = const Color(0xFF022C22);
                        borderColor = const Color(0xFF059669);
                      }
                      if (isWrong) {
                        bgColor = const Color(0xFF2D0A0A);
                        borderColor = const Color(0xFFDC2626);
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: _answered
                            ? null
                            : () => setState(() {
                                  _selectedAnswer = i;
                                  _answered = true;
                                }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quiz.options[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (showCorrect)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF059669),
                                  size: 20,
                                ),
                              if (isWrong)
                                const Icon(
                                  Icons.cancel_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // ── Resultado y botón ─────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _answered
                        ? Column(
                            key: const ValueKey('result'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (_selectedAnswer == quiz.correctIndex)
                                const Text(
                                  '¡Correcto! 🎉',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                )
                              else
                                Text(
                                  'La respuesta correcta era: "${quiz.options[quiz.correctIndex]}"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _isCompleting
                                    ? null
                                    : (_isAlreadyCompleted
                                        ? () => Navigator.pop(context)
                                        : _complete),
                                child: _isCompleting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isLastLesson
                                            ? 'Completar módulo'
                                            : 'Siguiente lección',
                                      ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],

                // ── Sin quiz: botón directo ───────────────────────────────
                if (quiz == null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isCompleting
                        ? null
                        : (_isAlreadyCompleted
                            ? () => Navigator.pop(context)
                            : _complete),
                    child: _isCompleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isLastLesson
                                ? 'Completar módulo'
                                : 'Siguiente lección',
                          ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
