import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper._instance);

class DatabaseHelper {
  DatabaseHelper._();
  static final _instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'zen_money.db');
    return openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT NOT NULL,
        icon      TEXT NOT NULL,
        color     TEXT NOT NULL,
        type      TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        type          TEXT NOT NULL,
        balance       REAL NOT NULL DEFAULT 0,
        color         TEXT NOT NULL,
        icon          TEXT NOT NULL,
        currency      TEXT,
        exchange_rate REAL NOT NULL DEFAULT 1.0,
        created_at    TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id  INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount      REAL NOT NULL,
        type        TEXT NOT NULL,
        date        TEXT NOT NULL,
        note        TEXT,
        FOREIGN KEY (account_id)  REFERENCES accounts(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id  INTEGER NOT NULL,
        limit_amount REAL NOT NULL,
        month        INTEGER NOT NULL,
        year         INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount  REAL NOT NULL DEFAULT 0,
        icon          TEXT NOT NULL,
        deadline      TEXT,
        created_at    TEXT NOT NULL
      )
    ''');

    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE accounts ADD COLUMN currency TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE accounts ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0');
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('goals');
    await db.delete('accounts');
  }

  Future<void> _seedData(Database db) async {
    // Default categories
    final cats = [
      {'name': 'Продукты',         'icon': '🛒', 'color': '#2EC274', 'type': 'expense', 'is_default': 1},
      {'name': 'Кафе',             'icon': '☕', 'color': '#F58C25', 'type': 'expense', 'is_default': 1},
      {'name': 'Транспорт',        'icon': '🚇', 'color': '#4169E1', 'type': 'expense', 'is_default': 1},
      {'name': 'ЖКХ',              'icon': '🏠', 'color': '#66AAFF', 'type': 'expense', 'is_default': 1},
      {'name': 'Развлечения',      'icon': '🎮', 'color': '#E84EB0', 'type': 'expense', 'is_default': 1},
      {'name': 'Одежда',           'icon': '👕', 'color': '#E84040', 'type': 'expense', 'is_default': 1},
      {'name': 'Здоровье',         'icon': '💊', 'color': '#9B59B6', 'type': 'expense', 'is_default': 1},
      {'name': 'Подписки',         'icon': '📺', 'color': '#BDBDBD', 'type': 'expense', 'is_default': 1},
      {'name': 'Зарплата',         'icon': '💼', 'color': '#2EC274', 'type': 'income',  'is_default': 1},
      {'name': 'Фриланс',          'icon': '💻', 'color': '#4169E1', 'type': 'income',  'is_default': 1},
      {'name': 'Прочие доходы',    'icon': '💰', 'color': '#F58C25', 'type': 'income',  'is_default': 1},
    ];
    for (final c in cats) {
      await db.insert('categories', c);
    }

    // Default accounts
    final now = DateTime.now().toIso8601String();
    await db.insert('accounts', {
      'name': 'Карта Сбербанк', 'type': 'debit',
      'balance': 85000.0, 'color': '#2EC274', 'icon': 'С', 'created_at': now,
    });
    await db.insert('accounts', {
      'name': 'Наличные', 'type': 'cash',
      'balance': 12000.0, 'color': '#BDBDBD', 'icon': 'Н', 'created_at': now,
    });

    // Sample transactions
    final txs = [
      {'account_id':1,'category_id':1,'amount':2400.0,'type':'expense','date':DateTime.now().toIso8601String(),'note':'Пятёрочка'},
      {'account_id':1,'category_id':3,'amount':380.0, 'type':'expense','date':DateTime.now().toIso8601String(),'note':'Яндекс Go'},
      {'account_id':1,'category_id':9,'amount':142000.0,'type':'income','date':DateTime.now().subtract(const Duration(days:1)).toIso8601String(),'note':'Зарплата'},
      {'account_id':1,'category_id':2,'amount':640.0, 'type':'expense','date':DateTime.now().subtract(const Duration(days:1)).toIso8601String(),'note':'Кофемания'},
      {'account_id':1,'category_id':6,'amount':4990.0,'type':'expense','date':DateTime.now().subtract(const Duration(days:2)).toIso8601String(),'note':'Спортмастер'},
    ];
    for (final t in txs) {
      await db.insert('transactions', t);
    }

    // Sample goals
    await db.insert('goals', {
      'name': 'Отпуск в Грузии', 'target_amount': 150000.0,
      'saved_amount': 78000.0, 'icon': '✈', 'created_at': now,
      'deadline': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
    });
    await db.insert('goals', {
      'name': 'Подушка безопасности', 'target_amount': 300000.0,
      'saved_amount': 210000.0, 'icon': '🛟', 'created_at': now,
    });
    await db.insert('goals', {
      'name': 'Новый ноутбук', 'target_amount': 120000.0,
      'saved_amount': 45000.0, 'icon': '💻', 'created_at': now,
      'deadline': DateTime.now().add(const Duration(days: 180)).toIso8601String(),
    });

    // Sample budgets (current month)
    final m = DateTime.now().month;
    final y = DateTime.now().year;
    final budgets = [
      {'category_id': 1, 'limit_amount': 25000.0, 'month': m, 'year': y},
      {'category_id': 2, 'limit_amount': 8000.0,  'month': m, 'year': y},
      {'category_id': 3, 'limit_amount': 6000.0,  'month': m, 'year': y},
      {'category_id': 4, 'limit_amount': 8000.0,  'month': m, 'year': y},
      {'category_id': 5, 'limit_amount': 5000.0,  'month': m, 'year': y},
      {'category_id': 6, 'limit_amount': 6000.0,  'month': m, 'year': y},
    ];
    for (final b in budgets) {
      await db.insert('budgets', b);
    }
  }
}
