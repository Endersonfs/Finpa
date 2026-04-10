import 'package:hive_flutter/hive_flutter.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2)
enum AccountType { 
  @HiveField(0) general, 
  @HiveField(1) bank, 
  @HiveField(2) savings, 
  @HiveField(3) credit, 
  @HiveField(4) cash 
}

extension AccountTypeX on AccountType {
  String get label {
    switch (this) {
      case AccountType.general: return 'General';
      case AccountType.bank: return 'Cuenta bancaria';
      case AccountType.savings: return 'Ahorro';
      case AccountType.credit: return 'Tarjeta de crédito';
      case AccountType.cash: return 'Efectivo';
    }
  }

  String get emoji {
    switch (this) {
      case AccountType.general: return '💼';
      case AccountType.bank: return '🏦';
      case AccountType.savings: return '🏺';
      case AccountType.credit: return '💳';
      case AccountType.cash: return '💵';
    }
  }

  bool get isAsset => this != AccountType.credit;
  bool get isLiability => this == AccountType.credit;
  bool get isSpendable =>
      this == AccountType.general ||
      this == AccountType.bank ||
      this == AccountType.cash;
}

@HiveType(typeId: 3)
class AccountModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final String name;
  @HiveField(3) final AccountType type;
  @HiveField(4) final double balance;
  @HiveField(5) final String? bankName;
  @HiveField(6) final String? color;
  @HiveField(7) final bool isDefault;
  @HiveField(8) final bool isActive;
  @HiveField(9) final int sortOrder;
  @HiveField(10) final DateTime createdAt;
  @HiveField(11) final bool isSynced;
  @HiveField(12) final bool isDeleted;

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.bankName,
    this.color,
    required this.isDefault,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    this.isSynced = true,
    this.isDeleted = false,
  });

  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? bankName,
    String? color,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'general'),
        orElse: () => AccountType.general,
      ),
      balance: (json['balance'] as num? ?? 0).toDouble(),
      bankName: json['bank_name'] as String?,
      color: json['color'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'bank_name': bankName,
      'color': color,
      'is_default': isDefault,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FinancialSummary {
  final double available;
  final double saved;
  final double owed;

  const FinancialSummary({
    required this.available,
    required this.saved,
    required this.owed,
  });

  const FinancialSummary.zeros() : available = 0, saved = 0, owed = 0;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      available: (json['available'] as num? ?? 0).toDouble(),
      saved: (json['saved'] as num? ?? 0).toDouble(),
      owed: (json['owed'] as num? ?? 0).toDouble(),
    );
  }
}
