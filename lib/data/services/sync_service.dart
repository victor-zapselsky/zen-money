import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';

class SyncService {
  static SupabaseClient get _sb => Supabase.instance.client;

  // Order matters: accounts before transactions (FK deps)
  // Categories are excluded from push — they use integer IDs seeded locally,
  // causing RLS conflicts when multiple users share the same IDs on upsert.
  static const _pushTables = [
    'accounts',
    'transactions',
    'budgets',
    'goals',
  ];

  static const _pullTables = [
    'categories',
    'accounts',
    'transactions',
    'budgets',
    'goals',
  ];

  /// Pushes all local SQLite data to Supabase (upsert by id + user_id).
  static Future<void> pushToCloud(DatabaseHelper dbHelper) async {
    if (!AuthService.isLoggedIn) return;
    final userId = AuthService.currentUser!.id;
    final db = await dbHelper.database;

    for (final table in _pushTables) {
      final rows = await db.query(table);
      if (rows.isEmpty) continue;
      final records = rows
          .map((r) => {...Map<String, dynamic>.from(r), 'user_id': userId})
          .toList();
      // Local ids are per-device autoincrement integers, so two different
      // users can generate the same id. Conflict must be resolved per-user
      // (id, user_id), not by id alone — requires a matching unique
      // constraint on (id, user_id) in Postgres for each table below.
      await _sb.from(table).upsert(records, onConflict: 'id,user_id');
    }
  }

  /// Deletes all user data from Supabase (except categories).
  static Future<void> clearCloudData() async {
    if (!AuthService.isLoggedIn) return;
    final userId = AuthService.currentUser!.id;
    const toDelete = ['transactions', 'budgets', 'goals', 'accounts'];
    for (final table in toDelete) {
      await _sb.from(table).delete().eq('user_id', userId);
    }
  }

  /// Pulls cloud data for this user into local SQLite (replaces local data).
  static Future<bool> pullFromCloud(DatabaseHelper dbHelper) async {
    if (!AuthService.isLoggedIn) return false;
    final userId = AuthService.currentUser!.id;
    final db = await dbHelper.database;

    bool hadData = false;
    for (final table in _pullTables) {
      final List<dynamic> records =
          await _sb.from(table).select().eq('user_id', userId);
      if (records.isEmpty) continue;
      hadData = true;

      await db.transaction((txn) async {
        await txn.delete(table);
        for (final rec in records) {
          final row = Map<String, dynamic>.from(rec as Map)
            ..remove('user_id')
            ..remove('updated_at');
          await txn.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
    return hadData;
  }
}
