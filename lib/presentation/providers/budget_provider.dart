import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';
import 'journal_provider.dart';

final budgetProvider = FutureProvider.autoDispose<List<BudgetModel>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(budgetRepositoryProvider).getForMonth(month.month, month.year);
});
