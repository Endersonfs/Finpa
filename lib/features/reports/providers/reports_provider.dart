import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/providers/transaction_provider.dart';

// Datos precalculados para los gráficos
class ReportData {
  final Map<String, double> monthlySummary; // {'income': x, 'expense': x}
  final Map<String, double> categoryExpenses; // {'food': x, 'transport': x, ...}
  final List<({int month, int year, double income, double expense})> last6Months;

  const ReportData({
    required this.monthlySummary,
    required this.categoryExpenses,
    required this.last6Months,
  });
}

// FutureProvider.family recibe ({int month, int year})
final reportsProvider = FutureProvider.autoDispose
    .family<ReportData, ({int month, int year})>((ref, period) async {
  final repo = ref.watch(transactionRepositoryProvider);

  // Datos del mes seleccionado
  final summary =
      await repo.monthlySummary(month: period.month, year: period.year);
  final catExpenses =
      await repo.categoryExpenses(month: period.month, year: period.year);

  // Últimos 6 meses para la barra y la línea
  final now = DateTime.now();
  final last6 = <({int month, int year, double income, double expense})>[];
  for (int i = 5; i >= 0; i--) {
    final dt = DateTime(now.year, now.month - i, 1);
    final s = await repo.monthlySummary(month: dt.month, year: dt.year);
    last6.add((
      month: dt.month,
      year: dt.year,
      income: s['income'] ?? 0,
      expense: s['expense'] ?? 0,
    ));
  }

  return ReportData(
    monthlySummary: summary,
    categoryExpenses: catExpenses,
    last6Months: last6,
  );
});

