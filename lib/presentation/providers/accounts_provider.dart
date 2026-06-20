import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import 'settings_provider.dart';

final accountsProvider = FutureProvider.autoDispose<List<AccountModel>>((ref) {
  return ref.watch(accountRepositoryProvider).getAll();
});

final totalBalanceProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(accountRepositoryProvider).getTotalBalance();
});

final displayTotalBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final total = await ref.watch(totalBalanceProvider.future);
  final rate = ref.watch(settingsProvider).displayRate;
  return total * rate;
});
