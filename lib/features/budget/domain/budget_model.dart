import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 4)
class Budget extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final String category;
  @HiveField(3) final double limitAmount;
  @HiveField(4) final double spent;
  @HiveField(5) final int month;
  @HiveField(6) final int year;
  @HiveField(7) final bool alertAt80;
  @HiveField(8) final bool isSynced;
  @HiveField(9) final bool isDeleted;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.spent,
    required this.month,
    required this.year,
    required this.alertAt80,
    this.isSynced = true,
    this.isDeleted = false,
  });

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? limitAmount,
    double? spent,
    int? month,
    int? year,
    bool? alertAt80,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      year: year ?? this.year,
      alertAt80: alertAt80 ?? this.alertAt80,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  double get percentage => limitAmount > 0 ? spent / limitAmount : 0;
  bool get isOverBudget => spent > limitAmount;
  bool get isNearLimit => percentage >= 0.8;
  double get remaining => limitAmount - spent;

  Color get statusColor {
    if (percentage > 0.8) return const Color(0xFFDC2626);
    if (percentage > 0.6) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      limitAmount: (json['limit_amount'] as num).toDouble(),
      spent: (json['spent'] as num? ?? 0).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      alertAt80: json['alert_at_80'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'limit_amount': limitAmount,
      'spent': spent,
      'month': month,
      'year': year,
      'alert_at_80': alertAt80,
    };
  }
}
