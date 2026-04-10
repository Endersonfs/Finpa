import 'package:flutter/material.dart';

class SavingGoal {
  final String id;
  final String userId;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const SavingGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  bool get isCompleted => currentAmount >= targetAmount;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  int get monthsRemaining {
    if (deadline == null) return 1;
    final now = DateTime.now();
    if (deadline!.isBefore(now)) return 1;
    return ((deadline!.year - now.year) * 12 +
            (deadline!.month - now.month))
        .clamp(1, 999);
  }

  double get requiredMonthlySaving {
    final needed = targetAmount - currentAmount;
    if (needed <= 0) return 0;
    return needed / monthsRemaining;
  }

  Color get progressColor {
    if (progress > 0.66) return const Color(0xFF059669);
    if (progress > 0.33) return const Color(0xFF2563EB);
    return const Color(0xFFD97706);
  }

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    return SavingGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num? ?? 0).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingGoal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

