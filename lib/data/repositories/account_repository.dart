import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/account_model.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(databaseHelperProvider)),
);

class AccountRepository {
  final DatabaseHelper _db;
  AccountRepository(this._db);

  Future<List<AccountModel>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('accounts', orderBy: 'created_at ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<double> getTotalBalance() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM accounts');
    return (result.first['total'] as num? ?? 0).toDouble();
  }

  Future<int> insert(AccountModel a) async {
    final db = await _db.database;
    return db.insert('accounts', a.toMap());
  }

  Future<void> update(AccountModel a) async {
    final db = await _db.database;
    await db.update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'account_id = ?', whereArgs: [id]);
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}
