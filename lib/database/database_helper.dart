import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stock.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE stock_exits ADD COLUMN is_synced INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE expenses ADD COLUMN is_synced INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE cotisations ADD COLUMN is_synced INTEGER DEFAULT 0");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE expenses ADD COLUMN uuid TEXT");
      await db.execute("ALTER TABLE cotisations ADD COLUMN uuid TEXT");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Produits (synchrisés depuis boutique-app via backend)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT,
        category TEXT,
        price REAL,
        quantity INTEGER DEFAULT 0,
        image_path TEXT,
        brandName TEXT,
        description TEXT
      )
    ''');

    // Dépenses
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reason TEXT,
        amount REAL,
        category TEXT,
        datetime TEXT,
        description TEXT,
        is_validated INTEGER DEFAULT 0,
        source TEXT DEFAULT 'caisse',
        financeur_id TEXT,
        is_synced INTEGER DEFAULT 0,
        uuid TEXT
      )
    ''');

    // Cotisations
    await db.execute('''
      CREATE TABLE cotisations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        date TEXT,
        note TEXT,
        source TEXT DEFAULT 'caisse',
        category TEXT,
        partner_id INTEGER,
        is_synced INTEGER DEFAULT 0,
        uuid TEXT
      )
    ''');

    // Retraits de cotisations
    await db.execute('''
      CREATE TABLE cotisation_withdrawals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cotisation_id INTEGER,
        amount REAL,
        date TEXT,
        motif TEXT,
        source TEXT
      )
    ''');

    // Sorties stock (ventes)
    await db.execute('''
      CREATE TABLE stock_exits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        name TEXT,
        product_id INTEGER,
        quantity INTEGER,
        amount REAL,
        client_id INTEGER,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Partenaires / Clients
    await db.execute('''
      CREATE TABLE partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        type TEXT,
        created_at TEXT
      )
    ''');
  }
}
