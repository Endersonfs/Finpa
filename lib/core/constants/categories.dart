import 'package:flutter/material.dart';

import '../../features/transactions/domain/transaction.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinPaCategory — categoría unificada con emoji, color y tipo
// ─────────────────────────────────────────────────────────────────────────────

class FinPaCategory {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final TransactionType type;

  const FinPaCategory({
    required this.id,
    required this.name,
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
    name: 'Comida',
    emoji: '🛒',
    color: Color(0xFFDC2626),
    type: TransactionType.expense,
  );

  static const transport = FinPaCategory(
    id: 'transport',
    name: 'Transporte',
    emoji: '🚗',
    color: Color(0xFF2563EB),
    type: TransactionType.expense,
  );

  static const entertainment = FinPaCategory(
    id: 'entertainment',
    name: 'Entretenimiento',
    emoji: '🎬',
    color: Color(0xFF7C3AED),
    type: TransactionType.expense,
  );

  static const health = FinPaCategory(
    id: 'health',
    name: 'Salud',
    emoji: '🏥',
    color: Color(0xFF0891B2),
    type: TransactionType.expense,
  );

  static const clothing = FinPaCategory(
    id: 'clothing',
    name: 'Ropa',
    emoji: '👗',
    color: Color(0xFFDB2777),
    type: TransactionType.expense,
  );

  static const housing = FinPaCategory(
    id: 'housing',
    name: 'Hogar',
    emoji: '🏠',
    color: Color(0xFF059669),
    type: TransactionType.expense,
  );

  static const services = FinPaCategory(
    id: 'services',
    name: 'Servicios',
    emoji: '📱',
    color: Color(0xFF6B7280),
    type: TransactionType.expense,
  );

  static const education = FinPaCategory(
    id: 'education',
    name: 'Educación',
    emoji: '📚',
    color: Color(0xFFD97706),
    type: TransactionType.expense,
  );

  static const otherExpense = FinPaCategory(
    id: 'other',
    name: 'Otros',
    emoji: '➕',
    color: Color(0xFF8892B0),
    type: TransactionType.expense,
  );

  // ── Ingresos ────────────────────────────────────────────────────────────────
  static const salary = FinPaCategory(
    id: 'salary',
    name: 'Salario',
    emoji: '💰',
    color: Color(0xFF059669),
    type: TransactionType.income,
  );

  static const freelance = FinPaCategory(
    id: 'freelance',
    name: 'Freelance',
    emoji: '💻',
    color: Color(0xFF2F7155),
    type: TransactionType.income,
  );

  static const business = FinPaCategory(
    id: 'business',
    name: 'Negocio',
    emoji: '🏪',
    color: Color(0xFF7C3AED),
    type: TransactionType.income,
  );

  static const investment = FinPaCategory(
    id: 'investment',
    name: 'Inversión',
    emoji: '📈',
    color: Color(0xFF0891B2),
    type: TransactionType.income,
  );

  static const gift = FinPaCategory(
    id: 'gift',
    name: 'Regalo',
    emoji: '🎁',
    color: Color(0xFFDB2777),
    type: TransactionType.income,
  );

  static const otherIncome = FinPaCategory(
    id: 'other_income',
    name: 'Otros',
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
  static String nameFor(String id)  => findById(id)?.name  ?? id;
  static Color  colorFor(String id) =>
      findById(id)?.color ?? const Color(0xFF8892B0);
}

