import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/providers/transaction_provider.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/constants/currencies.dart';

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
  // Observamos el stream para que el provider se actualice si las cuentas cambian, 
  // pero lo obtenemos como futuro para la lógica async.
  final accounts = await ref.watch(accountsStreamProvider.future);
  final currencyState = ref.watch(currencyNotifierProvider);
  final currencyNotifier = ref.read(currencyNotifierProvider.notifier);

  Future<Map<String, double>> getConvertedSummary(int m, int y) async {
    final txs = await repo.fetchAll(month: m, year: y);
    double inc = 0, exp = 0;
    for (final t in txs) {
      final acc = accounts.where((a) => a.id == t.accountId).firstOrNull;
      final tCurr = acc?.currency ?? AppCurrency.dop;
      final converted = currencyNotifier.convert(t.amount, tCurr, currencyState.baseCurrency);
      if (t.isIncome) inc += converted; else exp += converted;
    }
    return {'income': inc, 'expense': exp};
  }

  Future<Map<String, double>> getConvertedCatExpenses(int m, int y) async {
    final txs = await repo.fetchAll(month: m, year: y);
    final result = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      final acc = accounts.where((a) => a.id == t.accountId).firstOrNull;
      final tCurr = acc?.currency ?? AppCurrency.dop;
      final converted = currencyNotifier.convert(t.amount, tCurr, currencyState.baseCurrency);
      result[t.category] = (result[t.category] ?? 0) + converted;
    }
    return result;
  }

  // Datos del mes seleccionado
  final summary = await getConvertedSummary(period.month, period.year);
  final catExpenses = await getConvertedCatExpenses(period.month, period.year);

  // Últimos 6 meses
  final now = DateTime.now();
  final last6 = <({int month, int year, double income, double expense})>[];
  for (int i = 5; i >= 0; i--) {
    final dt = DateTime(now.year, now.month - i, 1);
    final s = await getConvertedSummary(dt.month, dt.year);
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
