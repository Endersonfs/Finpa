import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinPaDateUtils — utilidades de fechas en español
// ─────────────────────────────────────────────────────────────────────────────

abstract final class FinPaDateUtils {
  static final _dayMonth = DateFormat('d MMM', 'es');

  /// "Hoy" · "Ayer" · "Hace 3 días" · "15 mar"
  static String relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff <= 6) return 'Hace $diff días';
    return _dayMonth.format(d);
  }

  /// Nombre completo del mes (1=Enero … 12=Diciembre)
  static String monthName(int m) => const [
        'Enero',      'Febrero',   'Marzo',     'Abril',
        'Mayo',       'Junio',     'Julio',     'Agosto',
        'Septiembre', 'Octubre',   'Noviembre', 'Diciembre',
      ][m - 1];

  /// Nombre corto del mes (1=Ene … 12=Dic)
  static String monthShort(int m) => const [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ][m - 1];

  /// "Buenos días" · "Buenas tardes" · "Buenas noches"
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  // ── Compatibilidad con código existente ─────────────────────────────────────

  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime get endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }
}

