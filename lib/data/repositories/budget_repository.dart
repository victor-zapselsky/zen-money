import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/budget_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(databaseHelperProvider)),
);

class BudgetRepository {
  final DatabaseHelper _db;
  BudgetRepository(this._db);

  Future<List<BudgetModel>> getForMonth(int month, int year) async {
    final db = await _db.database;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery('''
      SELECT b.*,
             c.name  AS category_name,
             c.icon  AS category_icon,
             c.color AS category_color,
             COALESCE((
               SELECT SUM(t.amount * COALESCE(a.exchange_rate, 1.0))
               FROM transactions t
               LEFT JOIN accounts a ON a.id = t.account_id
               WHERE t.category_id = b.category_id
                 AND t.type = 'expense'
                 AND strftime('%Y-%m', t.date) = ?
             ), 0) AS spent_amount
      FROM budgets b
      JOIN categories c ON c.id = b.category_id
      WHERE b.month = ? AND b.year = ?
      ORDER BY b.limit_amount DESC
    ''', [key, month, year]);
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<int> insert(BudgetModel b) async {
    final db = await _db.database;
    return db.insert('budgets', b.toMap());
  }

  Future<void> update(BudgetModel b) async {
    final db = await _db.database;
    await db.update('budgets', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
