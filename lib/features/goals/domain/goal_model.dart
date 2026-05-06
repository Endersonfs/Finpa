import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/currencies.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 5)
class SavingGoal extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final String title;
  @HiveField(3) final String emoji;
  @HiveField(4) final double targetAmount;
  @HiveField(5) final double currentAmount;
  @HiveField(6) final DateTime? deadline;
  @HiveField(7) final DateTime createdAt;
  @HiveField(8) bool isSynced;
  @HiveField(9) bool isDeleted;
  @HiveField(10) final String currencyCode;

  SavingGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.createdAt,
    this.isSynced = true,
    this.isDeleted = false,
    this.currencyCode = 'DOP',
  });

  SavingGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
    String? currencyCode,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  // Helper para obtener AppCurrency
  AppCurrency get currency {
    return AppCurrency.values.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => AppCurrency.dop,
    );
  }

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
    if (progress > 0.33) return const Color(0xFF2F7155); 
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
      currencyCode: json['currency_code'] as String? ?? 'DOP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'emoji': emoji,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'currency_code': currencyCode,
    };
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
