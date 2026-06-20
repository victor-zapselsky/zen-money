import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'settings_provider.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final journalProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAll(month: month);
});

final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getMonthlySummary(month);
});

final displayMonthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final summary = await ref.watch(monthlySummaryProvider.future);
  final rate = ref.watch(settingsProvider).displayRate;
  return {
    'income': (summary['income'] ?? 0) * rate,
    'expense': (summary['expense'] ?? 0) * rate,
  };
});
