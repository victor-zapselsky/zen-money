import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/goal_model.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(ref.watch(databaseHelperProvider)),
);

class GoalRepository {
  final DatabaseHelper _db;
  GoalRepository(this._db);

  Future<List<GoalModel>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('goals', orderBy: 'created_at DESC');
    return rows.map(GoalModel.fromMap).toList();
  }

  Future<int> insert(GoalModel g) async {
    final db = await _db.database;
    return db.insert('goals', g.toMap());
  }

  Future<void> update(GoalModel g) async {
    final db = await _db.database;
    await db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> addSaving(int id, double amount) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE goals SET saved_amount = saved_amount + ? WHERE id = ?',
      [amount, id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
