import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseHelperProvider)),
);

class CategoryRepository {
  final DatabaseHelper _db;
  CategoryRepository(this._db);

  Future<List<CategoryModel>> getAll({String? type}) async {
    final db = await _db.database;
    final rows = await db.query(
      'categories',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'is_default DESC, name ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> insert(CategoryModel c) async {
    final db = await _db.database;
    return db.insert('categories', c.toMap());
  }

  Future<void> update(CategoryModel c) async {
    final db = await _db.database;
    await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
