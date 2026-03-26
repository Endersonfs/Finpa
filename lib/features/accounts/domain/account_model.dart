// ─────────────────────────────────────────────────────────────────────────────
//  Domain — AccountModel, TransferModel, FinancialSummary
// ─────────────────────────────────────────────────────────────────────────────

enum AccountType { general, bank, savings, credit, cash }

extension AccountTypeX on AccountType {
  String get label {
    switch (this) {
      case AccountType.general:
        return 'General';
      case AccountType.bank:
        return 'Cuenta bancaria';
      case AccountType.savings:
        return 'Ahorro';
      case AccountType.credit:
        return 'Tarjeta de crédito';
      case AccountType.cash:
        return 'Efectivo';
    }
  }

  String get emoji {
    switch (this) {
      case AccountType.general:
        return '💼';
      case AccountType.bank:
        return '🏦';
      case AccountType.savings:
        return '🏺';
      case AccountType.credit:
        return '💳';
      case AccountType.cash:
        return '💵';
    }
  }

  /// Activos: todo menos tarjeta de crédito.
  bool get isAsset => this != AccountType.credit;

  /// Pasivos: solo tarjeta de crédito.
  bool get isLiability => this == AccountType.credit;

  /// Dinero disponible para gastar: general, banco, efectivo.
  bool get isSpendable =>
      this == AccountType.general ||
      this == AccountType.bank ||
      this == AccountType.cash;
}

// ─────────────────────────────────────────────────────────────────────────────

class AccountModel {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String? bankName;
  final String? color;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const AccountModel({
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
  });

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────

class TransferModel {
  final String id;
  final String userId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const TransferModel({
    required this.id,
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class FinancialSummary {
  /// Suma de saldos en cuentas isSpendable.
  final double available;

  /// Suma de saldos en cuentas savings.
  final double saved;

  /// Suma de saldos en cuentas credit (positivo = lo que debes).
  final double owed;

  const FinancialSummary({
    required this.available,
    required this.saved,
    required this.owed,
  });

  const FinancialSummary.zeros()
      : available = 0,
        saved = 0,
        owed = 0;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      available: (json['available'] as num? ?? 0).toDouble(),
      saved: (json['saved'] as num? ?? 0).toDouble(),
      owed: (json['owed'] as num? ?? 0).toDouble(),
    );
  }
}
