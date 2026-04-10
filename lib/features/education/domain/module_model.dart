import 'package:flutter/material.dart';

import 'lesson_model.dart';

class ModuleModel {
  final String id;
  final String title;
  final String category;
  final String iconEmoji;
  final List<LessonModel> lessons;
  final bool isUnlocked;
  final List<String> completedLessonIds;

  const ModuleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.iconEmoji,
    required this.lessons,
    required this.isUnlocked,
    required this.completedLessonIds,
  });

  int get completedCount => completedLessonIds.length;
  int get totalCount => lessons.length;
  double get progress => totalCount > 0 ? completedCount / totalCount : 0;
  bool get isCompleted => completedCount >= totalCount && totalCount > 0;

  Color get progressColor {
    if (isCompleted) return const Color(0xFF059669);
    if (progress > 0) return const Color(0xFF2F7155);
    return const Color(0xFF9CA3AF);
  }
}

