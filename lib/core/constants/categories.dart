import 'package:flutter/material.dart';

import '../../features/transactions/domain/transaction.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinPaCategory — categoría unificada con emoji, color y tipo
// ─────────────────────────────────────────────────────────────────────────────

class FinPaCategory {
  final String id;
  final String emoji;
  final Color color;
  final TransactionType type;

  const FinPaCategory({
    required this.id,
    required this.emoji,
    required this.color,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Catálogo global
// ─────────────────────────────────────────────────────────────────────────────

abstract final class FinPaCategories {
  // ── Gastos ──────────────────────────────────────────────────────────────────
  static const food = FinPaCategory(
    id: 'food',
    emoji: '🛒',
    color: Color(0xFFDC2626),
    type: TransactionType.expense,
  );

  static const transport = FinPaCategory(
    id: 'transport',
    emoji: '🚗',
    color: Color(0xFF2563EB),
    type: TransactionType.expense,
  );

  static const entertainment = FinPaCategory(
    id: 'entertainment',
    emoji: '🎬',
    color: Color(0xFF7C3AED),
    type: TransactionType.expense,
  );

  static const health = FinPaCategory(
    id: 'health',
    emoji: '🏥',
    color: Color(0xFF0891B2),
    type: TransactionType.expense,
  );

  static const clothing = FinPaCategory(
    id: 'clothing',
    emoji: '👗',
    color: Color(0xFFDB2777),
    type: TransactionType.expense,
  );

  static const housing = FinPaCategory(
    id: 'housing',
    emoji: '🏠',
    color: Color(0xFF059669),
    type: TransactionType.expense,
  );

  static const services = FinPaCategory(
    id: 'services',
    emoji: '📱',
    color: Color(0xFF6B7280),
    type: TransactionType.expense,
  );

  static const education = FinPaCategory(
    id: 'education',
    emoji: '📚',
    color: Color(0xFFD97706),
    type: TransactionType.expense,
  );

  static const otherExpense = FinPaCategory(
    id: 'other',
    emoji: '➕',
    color: Color(0xFF8892B0),
    type: TransactionType.expense,
  );

  // ── Ingresos ────────────────────────────────────────────────────────────────
  static const salary = FinPaCategory(
    id: 'salary',
    emoji: '💰',
    color: Color(0xFF059669),
    type: TransactionType.income,
  );

  static const freelance = FinPaCategory(
    id: 'freelance',
    emoji: '💻',
    color: Color(0xFF2F7155),
    type: TransactionType.income,
  );

  static const business = FinPaCategory(
    id: 'business',
    emoji: '🏪',
    color: Color(0xFF7C3AED),
    type: TransactionType.income,
  );

  static const investment = FinPaCategory(
    id: 'investment',
    emoji: '📈',
    color: Color(0xFF0891B2),
    type: TransactionType.income,
  );

  static const gift = FinPaCategory(
    id: 'gift',
    emoji: '🎁',
    color: Color(0xFFDB2777),
    type: TransactionType.income,
  );

  static const otherIncome = FinPaCategory(
    id: 'other_income',
    emoji: '➕',
    color: Color(0xFF8892B0),
    type: TransactionType.income,
  );

  // ── Listas agrupadas ────────────────────────────────────────────────────────
  static const List<FinPaCategory> expenses = [
    food, transport, entertainment, health, clothing,
    housing, services, education, otherExpense,
  ];

  static const List<FinPaCategory> incomes = [
    salary, freelance, business, investment, gift, otherIncome,
  ];

  static const List<FinPaCategory> all = [...expenses, ...incomes];

  // ── Lookup ──────────────────────────────────────────────────────────────────
  static FinPaCategory? findById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static String emojiFor(String id) => findById(id)?.emoji ?? '📊';
  
  static Color  colorFor(String id) =>
      findById(id)?.color ?? const Color(0xFF8892B0);
}

