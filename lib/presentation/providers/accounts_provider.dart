import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';

final accountsProvider = FutureProvider.autoDispose<List<AccountModel>>((ref) {
  return ref.watch(accountRepositoryProvider).getAll();
});

final totalBalanceProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(accountRepositoryProvider).getTotalBalance();
});
