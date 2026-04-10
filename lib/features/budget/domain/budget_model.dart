import 'package:flutter/material.dart';

class Budget {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final double spent;
  final int month;
  final int year;
  final bool alertAt80;

  const Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.spent,
    required this.month,
    required this.year,
    required this.alertAt80,
  });

  /// Porcentaje consumido (0.0 – puede superar 1.0)
  double get percentage => limitAmount > 0 ? spent / limitAmount : 0;

  /// true si superó el límite
  bool get isOverBudget => spent > limitAmount;

  /// true si llegó al 80%
  bool get isNearLimit => percentage >= 0.8;

  /// Monto restante (puede ser negativo si superó el límite)
  double get remaining => limitAmount - spent;

  /// Color semántico según porcentaje:
  /// >80% (o superado) → rojo #DC2626
  /// >60% → amarillo #D97706
  /// else → verde #059669
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

