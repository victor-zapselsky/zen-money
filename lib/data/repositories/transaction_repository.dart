import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(databaseHelperProvider)),
);

class TransactionRepository {
  final DatabaseHelper _db;
  TransactionRepository(this._db);

  Future<List<TransactionModel>> getAll({DateTime? month}) async {
    final db = await _db.database;
    String where = '';
    List<dynamic> args = [];
    if (month != null) {
      where = "WHERE strftime('%Y-%m', t.date) = ?";
      args = ['${month.year}-${month.month.toString().padLeft(2,'0')}'];
    }
    final rows = await db.rawQuery('''
      SELECT t.*,
             a.name     AS account_name,
             a.currency AS account_currency,
             c.name     AS category_name,
             c.icon     AS category_icon,
             c.color    AS category_color
      FROM transactions t
      LEFT JOIN accounts   a ON a.id = t.account_id
      LEFT JOIN categories c ON c.id = t.category_id
      $where
      ORDER BY t.date DESC
    ''', args);
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    final db = await _db.database;
    final key = '${month.year}-${month.month.toString().padLeft(2,'0')}';
    final rows = await db.rawQuery('''
      SELECT t.type,
             SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE strftime('%Y-%m', t.date) = ?
      GROUP BY t.type
    ''', [key]);
    double income = 0, expense = 0;
    for (final r in rows) {
      if (r['type'] == 'income')  income  = (r['total'] as num).toDouble();
      if (r['type'] == 'expense') expense = (r['total'] as num).toDouble();
    }
    return {'income': income, 'expense': expense};
  }

  Future<List<Map<String, dynamic>>> getCategorySpending(DateTime month) async {
    final db = await _db.database;
    final key = '${month.year}-${month.month.toString().padLeft(2,'0')}';
    return db.rawQuery('''
      SELECT c.id, c.name, c.icon, c.color,
             SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON c.id = t.category_id
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE t.type = 'expense'
        AND strftime('%Y-%m', t.date) = ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [key]);
  }

  Future<List<Map<String, dynamic>>> getDailyTotals({int days = 30}) async {
    final db = await _db.database;
    final cutoff = DateTime.now().subtract(Duration(days: days - 1));
    final cutoffStr =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    return db.rawQuery('''
      SELECT strftime('%Y-%m-%d', t.date) as day,
             SUM(CASE WHEN t.type='income'  THEN t.amount ELSE 0 END) as income,
             SUM(CASE WHEN t.type='expense' THEN t.amount ELSE 0 END) as expense
      FROM transactions t
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE date(t.date) >= ?
      GROUP BY day
      ORDER BY day ASC
    ''', [cutoffStr]);
  }

  Future<List<Map<String, dynamic>>> getWeeklyTotals({int weeks = 52}) async {
    final db = await _db.database;
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    final cutoffStr =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    return db.rawQuery('''
      SELECT
        date(t.date, '-' || cast((strftime('%w', t.date) + 6) % 7 as text) || ' days') as week_start,
        SUM(CASE WHEN t.type='income'  THEN t.amount * COALESCE(a.exchange_rate, 1.0) ELSE 0 END) as income,
        SUM(CASE WHEN t.type='expense' THEN t.amount * COALESCE(a.exchange_rate, 1.0) ELSE 0 END) as expense
      FROM transactions t
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE date(t.date) >= ?
      GROUP BY week_start
      ORDER BY week_start ASC
    ''', [cutoffStr]);
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals({int months = 12}) async {
    final db = await _db.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}';
    return db.rawQuery('''
      SELECT strftime('%Y-%m', t.date) as month,
             SUM(CASE WHEN t.type='income'  THEN t.amount ELSE 0 END) as income,
             SUM(CASE WHEN t.type='expense' THEN t.amount ELSE 0 END) as expense
      FROM transactions t
      LEFT JOIN accounts a ON a.id = t.account_id
      WHERE strftime('%Y-%m', t.date) >= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [startStr]);
  }

  Future<List<Map<String, dynamic>>> getYearlyTotals() async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT strftime('%Y', t.date) as year,
             SUM(CASE WHEN t.type='income'  THEN t.amount ELSE 0 END) as income,
             SUM(CASE WHEN t.type='expense' THEN t.amount ELSE 0 END) as expense
      FROM transactions t
      LEFT JOIN accounts a ON a.id = t.account_id
      GROUP BY year
      ORDER BY year ASC
    ''');
  }

  Future<int> insert(TransactionModel t) async {
    final db = await _db.database;
    final id = await db.insert('transactions', t.toMap());
    // Update account balance
    final delta = t.type == 'income' ? t.amount : -t.amount;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [delta, t.accountId],
    );
    return id;
  }

  Future<void> update(TransactionModel t) async {
    final db = await _db.database;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [t.id]);
    if (rows.isEmpty) return;
    final old = TransactionModel.fromMap(rows.first);
    // Reverse old balance effect
    final oldDelta = old.type == 'income' ? -old.amount : old.amount;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [oldDelta, old.accountId],
    );
    // Apply new balance effect
    await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    final newDelta = t.type == 'income' ? t.amount : -t.amount;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [newDelta, t.accountId],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final t = TransactionModel.fromMap(rows.first);
    final delta = t.type == 'income' ? -t.amount : t.amount;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [delta, t.accountId],
    );
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
