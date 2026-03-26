import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CurrencyFormatter — Peso Dominicano (RD$)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CurrencyFormatter {
  static final _rdNoDecimal = NumberFormat.currency(
    locale: 'es',
    symbol: 'RD\$',
    decimalDigits: 0,
  );

  static final _rdDecimal = NumberFormat.currency(
    locale: 'es',
    symbol: 'RD\$',
    decimalDigits: 2,
  );

  /// "RD\$42,500"
  static String formatRD(double amount) => _rdNoDecimal.format(amount);

  /// "RD\$42,500.00"
  static String formatRDDecimal(double amount) => _rdDecimal.format(amount);

  /// "RD\$42.5K" · "RD\$1.2M"
  static String formatCompact(double amount) {
    final abs = amount.abs();
    if (abs >= 1_000_000) {
      return 'RD\$${(amount / 1_000_000).toStringAsFixed(1)}M';
    } else if (abs >= 1_000) {
      return 'RD\$${(amount / 1_000).toStringAsFixed(1)}K';
    }
    return formatRD(amount);
  }

  /// "+RD\$42,500" · "-RD\$42,500"
  static String formatDiff(double amount) {
    final formatted = _rdNoDecimal.format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }
}
