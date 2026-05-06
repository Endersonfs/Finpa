import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinPaDateUtils — utilidades de fechas multidioma
// ─────────────────────────────────────────────────────────────────────────────

abstract final class FinPaDateUtils {
  /// "Hoy" · "Ayer" · "Hace 3 días" · "15 mar"
  static String relativeDate(DateTime d, {String lang = 'es'}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return lang == 'es' ? 'Hoy' : 'Today';
    if (diff == 1) return lang == 'es' ? 'Ayer' : 'Yesterday';
    if (diff <= 6) return lang == 'es' ? 'Hace $diff días' : '$diff days ago';
    return DateFormat('d MMM', lang).format(d);
  }

  /// Nombre completo del mes (1=Enero … 12=Diciembre)
  static String monthName(int m, {String lang = 'es'}) {
    if (lang == 'es') {
      return const [
        'Enero',      'Febrero',   'Marzo',     'Abril',
        'Mayo',       'Junio',     'Julio',     'Agosto',
        'Septiembre', 'Octubre',   'Noviembre', 'Diciembre',
      ][m - 1];
    }
    return const [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ][m - 1];
  }

  /// Nombre corto del mes (1=Ene … 12=Dic)
  static String monthShort(int m, {String lang = 'es'}) {
    if (lang == 'es') {
      return const [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ][m - 1];
    }
    return const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][m - 1];
  }

  /// "Buenos días" · "Buenas tardes" · "Buenas noches"
  static String greeting({String lang = 'es'}) {
    final hour = DateTime.now().hour;
    if (hour < 12) return lang == 'es' ? 'Buenos días' : 'Good morning';
    if (hour < 19) return lang == 'es' ? 'Buenas tardes' : 'Good afternoon';
    return lang == 'es' ? 'Buenas noches' : 'Good evening';
  }

  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime get endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }
}
