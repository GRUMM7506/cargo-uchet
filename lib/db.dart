import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const fileName = 'cargo_uchet.db';
  static const version = 2;

  static Future<String> path() async => p.join(await getDatabasesPath(), fileName);

  static Future<Database> open() async {
    return openDatabase(
      await path(),
      version: version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await _createV1(db);
        await _upgradeTo2(db);
      },
      onUpgrade: (db, from, to) async {
        if (from < 2) await _upgradeTo2(db);
      },
    );
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
        description TEXT NOT NULL DEFAULT '',
        weight_kg REAL,
        quantity INTEGER,
        amount_cents INTEGER NOT NULL,
        accepted_at TEXT NOT NULL,
        done_at TEXT,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
        order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
        amount_cents INTEGER NOT NULL,
        paid_at TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        spent_at TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('CREATE INDEX idx_orders_client ON orders(client_id)');
    await db.execute('CREATE INDEX idx_payments_client ON payments(client_id)');
  }

  /// v2: тарифы (цена за кг / шт), трек-код, доплата, личная цена клиента, настройки.
  static Future<void> _upgradeTo2(Database db) async {
    await db.execute("ALTER TABLE orders ADD COLUMN pricing TEXT NOT NULL DEFAULT 'fixed'");
    await db.execute('ALTER TABLE orders ADD COLUMN rate_cents INTEGER');
    await db.execute('ALTER TABLE orders ADD COLUMN extra_cents INTEGER NOT NULL DEFAULT 0');
    await db.execute("ALTER TABLE orders ADD COLUMN code TEXT NOT NULL DEFAULT ''");
    await db.execute('ALTER TABLE clients ADD COLUMN rate_kg_cents INTEGER');
    await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  }

  /// Проверяет, что файл — наша база (для восстановления из копии).
  static Future<bool> isValidBackup(String filePath) async {
    Database? db;
    try {
      db = await openDatabase(filePath, readOnly: true, singleInstance: false);
      final rows = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final names = rows.map((r) => r['name']).toSet();
      return names.containsAll(['clients', 'orders', 'payments', 'expenses']);
    } catch (_) {
      return false;
    } finally {
      await db?.close();
    }
  }
}
