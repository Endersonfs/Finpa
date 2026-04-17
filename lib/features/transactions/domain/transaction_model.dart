import 'package:hive_flutter/hive_flutter.dart';
import 'transaction.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final double amount;
  @HiveField(3) final String type;
  @HiveField(4) final String category;
  @HiveField(5) final String? description;
  @HiveField(6) final String date;
  @HiveField(7) final String createdAt;
  @HiveField(8) bool isSynced;
  @HiveField(9) bool isDeleted;
  @HiveField(10) final String? accountId;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
    this.isSynced = true,
    this.isDeleted = false,
    this.accountId,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? category,
    String? description,
    String? date,
    String? createdAt,
    bool? isSynced,
    bool? isDeleted,
    String? accountId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      accountId: accountId ?? this.accountId,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      date: json['date'] as String,
      createdAt: json['created_at'] as String,
      accountId: json['account_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'date': date,
      'created_at': createdAt,
      'account_id': accountId,
    };
  }

  Transaction toTransaction() {
    return Transaction(
      id: id,
      userId: userId,
      accountId: accountId,
      amount: amount,
      type: type == 'income' ? TransactionType.income : TransactionType.expense,
      category: category,
      description: description,
      date: DateTime.parse(date),
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory TransactionModel.fromTransaction(Transaction t, {bool isSynced = true, bool isDeleted = false}) {
    return TransactionModel(
      id: t.id,
      userId: t.userId,
      accountId: t.accountId,
      amount: t.amount,
      type: t.type == TransactionType.income ? 'income' : 'expense',
      category: t.category,
      description: t.description,
      date: t.date.toIso8601String().split('T').first,
      createdAt: t.createdAt.toIso8601String(),
      isSynced: isSynced,
      isDeleted: isDeleted,
    );
  }
}
