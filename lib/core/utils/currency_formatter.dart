import 'package:intl/intl.dart';
import '../constants/currencies.dart';

// CurrencyFormatter - Soporte Multimoneda

abstract final class CurrencyFormatter {
  static NumberFormat _getFormatter(AppCurrency? currency, {int decimalDigits = 0}) {
    final curr = currency ?? AppCurrency.dop;
    return NumberFormat.currency(
      locale: curr.locale,
      symbol: curr.symbol,
      decimalDigits: decimalDigits,
    );
  }

  /// "RD\$42,500" or "\$42,500"
  static String format(double amount, {AppCurrency? currency}) => 
      _getFormatter(currency).format(amount);

  /// "RD\$42,500.00"
  static String formatDecimal(double amount, {AppCurrency? currency}) => 
      _getFormatter(currency, decimalDigits: 2).format(amount);

  /// "RD\$42.5K", "\$1.2M", "€3.5B"
  static String formatCompact(double amount, {AppCurrency? currency}) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    final curr = currency ?? AppCurrency.dop;
    final symbol = curr.symbol;

    if (abs >= 1e12) {
      return '$sign$symbol${_formatCompactValue(abs / 1e12)}T';
    } else if (abs >= 1e9) {
      return '$sign$symbol${_formatCompactValue(abs / 1e9)}B';
    } else if (abs >= 1e6) {
      return '$sign$symbol${_formatCompactValue(abs / 1e6)}M';
    } else if (abs >= 1000) {
      return '$sign$symbol${_formatCompactValue(abs / 1000)}K';
    }
    return format(amount, currency: curr);
  }

  static String _formatCompactValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // Limit to 1 decimal place, remove trailing zero if any
    String formatted = value.toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      return formatted.substring(0, formatted.length - 2);
    }
    return formatted;
  }

  /// "+RD\$42,500" or "-RD\$42,500"
  static String formatDiff(double amount, {AppCurrency? currency}) {
    final formatted = _getFormatter(currency).format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  // Alias para mantener compatibilidad temporal si es necesario
  static String formatRD(double amount) => format(amount, currency: AppCurrency.dop);
}
