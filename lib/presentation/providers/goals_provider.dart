import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';

final goalsProvider = FutureProvider.autoDispose<List<GoalModel>>((ref) {
  return ref.watch(goalRepositoryProvider).getAll();
});
