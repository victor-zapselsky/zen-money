import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository.dart';
import 'journal_provider.dart';

enum ReportPeriod { days, weeks, months, years }
enum ReportType { total, income, expense }

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.months);
final reportTypeProvider   = StateProvider<ReportType>((ref)   => ReportType.expense);

final categorySpendingProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionRepositoryProvider).getCategorySpending(month);
});

final chartDataProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final repo   = ref.watch(transactionRepositoryProvider);
  final now    = DateTime.now();

  switch (period) {
    case ReportPeriod.days:
      final raw = await repo.getDailyTotals(days: 30);
      return _fillDays(raw, 30, now);
    case ReportPeriod.weeks:
      final raw = await repo.getWeeklyTotals(weeks: 52);
      return _fillWeeks(raw, 52, now);
    case ReportPeriod.months:
      final raw = await repo.getMonthlyTotals(months: 12);
      return _fillMonths(raw, 12, now);
    case ReportPeriod.years:
      return repo.getYearlyTotals();
  }
});

List<Map<String, dynamic>> _fillDays(
    List<Map<String, dynamic>> raw, int days, DateTime now) {
  final map = <String, Map<String, dynamic>>{
    for (final r in raw) r['day'] as String: r,
  };
  return List.generate(days, (i) {
    final d = DateTime(now.year, now.month, now.day - (days - 1 - i));
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return map[key] ?? {'day': key, 'income': 0, 'expense': 0};
  });
}

List<Map<String, dynamic>> _fillWeeks(
    List<Map<String, dynamic>> raw, int weeks, DateTime now) {
  final map = <String, Map<String, dynamic>>{
    for (final r in raw)
      if ((r['week_start'] as String?)?.isNotEmpty == true)
        r['week_start'] as String: r,
  };
  final thisMonday =
      DateTime(now.year, now.month, now.day - (now.weekday - 1));
  return List.generate(weeks, (i) {
    final ws = thisMonday.subtract(Duration(days: (weeks - 1 - i) * 7));
    final key =
        '${ws.year}-${ws.month.toString().padLeft(2, '0')}-${ws.day.toString().padLeft(2, '0')}';
    return map[key] ?? {'week_start': key, 'income': 0, 'expense': 0};
  });
}

List<Map<String, dynamic>> _fillMonths(
    List<Map<String, dynamic>> raw, int months, DateTime now) {
  final map = <String, Map<String, dynamic>>{
    for (final r in raw) r['month'] as String: r,
  };
  return List.generate(months, (i) {
    final d = DateTime(now.year, now.month - (months - 1 - i));
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    return map[key] ?? {'month': key, 'income': 0, 'expense': 0};
  });
}
