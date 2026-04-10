// Para habilitar el TypeAdapter de Hive, agrega:
//   part 'transaction_model.g.dart';
// y ejecuta: flutter pub run build_runner build
import 'package:hive_flutter/hive_flutter.dart';

import 'transaction.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double amount;

  /// 'income' o 'expense'
  @HiveField(3)
  final String type;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String? description;

  /// Fecha en formato ISO 8601 (solo la parte de fecha: yyyy-MM-dd)
  @HiveField(6)
  final String date;

  /// Fecha-hora de creación en ISO 8601
  @HiveField(7)
  final String createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
  });

  /// Convierte este modelo al domain entity [Transaction].
  Transaction toTransaction() {
    return Transaction(
      id: id,
      userId: userId,
      amount: amount,
      type: type == 'income' ? TransactionType.income : TransactionType.expense,
      category: category,
      description: description,
      date: DateTime.parse(date),
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// Crea un [TransactionModel] a partir del domain entity [Transaction].
  factory TransactionModel.fromTransaction(Transaction t) {
    return TransactionModel(
      id: t.id,
      userId: t.userId,
      amount: t.amount,
      type: t.type == TransactionType.income ? 'income' : 'expense',
      category: t.category,
      description: t.description,
      date: t.date.toIso8601String().split('T').first,
      createdAt: t.createdAt.toIso8601String(),
    );
  }
}

