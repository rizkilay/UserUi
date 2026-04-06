import 'database_helper.dart';
import '../models/stock_exit.dart';

class ExitDao {
  Future<void> insert(StockExit exit) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Insérer la sortie de stock
      await txn.insert('stock_exits', exit.toMap());

      // 2. Diminuer la quantité du produit localement
      await txn.rawUpdate('''
        UPDATE products 
        SET quantity = MAX(0, quantity - ?) 
        WHERE id = ?
      ''', [exit.quantity, exit.productId]);
    });
  }

  /// Toutes les sorties sans doublon par UUID (résumé par facture)
  Future<List<StockExit>> getAllUniqueByUuid() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT
        MAX(exit.id) as id,
        exit.uuid,
        exit.name,
        0 as product_id,
        '' AS product_name,
        SUM(exit.quantity) as quantity,
        SUM(exit.amount) as amount,
        exit.client_id,
        MAX(exit.created_at) as created_at
      FROM stock_exits exit
      GROUP BY exit.uuid, exit.name, exit.client_id
      ORDER BY MAX(exit.id) DESC
    ''');
    return res.map((e) => StockExit.fromMap(e)).toList();
  }

  Future<List<StockExit>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT
        exit.id,
        exit.uuid,
        exit.name,
        exit.product_id,
        IFNULL(p.name, '') AS product_name,
        p.category as category,
        exit.quantity,
        exit.amount,
        exit.client_id,
        exit.created_at
      FROM stock_exits exit
      LEFT JOIN products p ON p.id = exit.product_id
      ORDER BY exit.id DESC
    ''');
    return res.map((e) => StockExit.fromMap(e)).toList();
  }

  Future<StockExit?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT
        exit.id, exit.uuid, exit.name, exit.product_id,
        IFNULL(p.name, '') AS product_name,
        p.category as category,
        exit.quantity, exit.amount, exit.client_id, exit.created_at
      FROM stock_exits exit
      LEFT JOIN products p ON p.id = exit.product_id
      WHERE exit.id = ?
      LIMIT 1
    ''', [id]);
    if (res.isEmpty) return null;
    return StockExit.fromMap(res.first);
  }

  Future<List<StockExit>> getByUuid(String uuid) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT
        exit.id, exit.uuid, exit.name, exit.product_id,
        IFNULL(p.name, '') AS product_name,
        p.category as category,
        exit.quantity, exit.amount, exit.client_id, exit.created_at
      FROM stock_exits exit
      LEFT JOIN products p ON p.id = exit.product_id
      WHERE exit.uuid = ?
      ORDER BY exit.id DESC
    ''', [uuid]);
    return res.map((e) => StockExit.fromMap(e)).toList();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Récupérer la sortie pour savoir quel produit et quelle quantité restaurer
      final res = await txn.query('stock_exits', where: 'id = ?', whereArgs: [id]);
      if (res.isNotEmpty) {
        final exit = StockExit.fromMap(res.first);

        // 2. Restaurer le stock
        await txn.rawUpdate('''
          UPDATE products 
          SET quantity = quantity + ? 
          WHERE id = ?
        ''', [exit.quantity, exit.productId]);
      }

      // 3. Supprimer l'entrée
      await txn.delete('stock_exits', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteByUuid(String uuid) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Récupérer toutes les sorties associées à cet UUID
      final res = await txn.query('stock_exits', where: 'uuid = ?', whereArgs: [uuid]);
      for (var row in res) {
        final exit = StockExit.fromMap(row);
        // 2. Restaurer le stock pour chaque produit
        await txn.rawUpdate('''
          UPDATE products 
          SET quantity = quantity + ? 
          WHERE id = ?
        ''', [exit.quantity, exit.productId]);
      }

      // 3. Supprimer par UUID
      await txn.delete('stock_exits', where: 'uuid = ?', whereArgs: [uuid]);
    });
  }

  Future<void> update(StockExit exit) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'stock_exits',
      exit.toMap(),
      where: 'id = ?',
      whereArgs: [exit.id],
    );
  }

  Future<double> getTotalSales() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT IFNULL(SUM(amount), 0) as total FROM stock_exits');
    final v = res.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<double> getTodaySales() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final res = await db.rawQuery(
      'SELECT IFNULL(SUM(amount), 0) as total FROM stock_exits WHERE created_at BETWEEN ? AND ?',
      [start, end],
    );
    final v = res.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<double> getMonthlySales() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();
    final res = await db.rawQuery(
      'SELECT IFNULL(SUM(amount), 0) as total FROM stock_exits WHERE created_at BETWEEN ? AND ?',
      [start, end],
    );
    final v = res.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<Map<String, dynamic>?> getTopSellingProduct() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT 
        IFNULL(p.name, exit.name) as name, 
        SUM(exit.quantity) as total_qty
      FROM stock_exits exit
      LEFT JOIN products p ON p.id = exit.product_id
      GROUP BY exit.product_id, exit.name
      ORDER BY total_qty DESC
      LIMIT 1
    ''');
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<List<StockExit>> getUnsynced() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('stock_exits', where: 'is_synced = 0');
    return res.map((e) => StockExit.fromMap(e)).toList();
  }

  Future<void> markAsSyncedWithTimestamp(List<int> ids, String timestamp) async {
    if (ids.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'stock_exits',
      {
        'is_synced': 1,
        'synced_at': timestamp,
      },
      where: 'id IN (${ids.join(',')})',
    );
  }

  Future<List<StockExit>> getSalesNotYetOnServer(String? serverTime) async {
    final db = await DatabaseHelper.instance.database;
    if (serverTime == null) {
      // Si on n'a pas de temps serveur, on prend tous les ventes locales (synced ou non)
      // car on ne sait pas si elles sont dans le snapshot
      final res = await db.query('stock_exits');
      return res.map((e) => StockExit.fromMap(e)).toList();
    }
    
    // Une vente n'est pas sur le serveur si :
    // 1. Elle n'est pas encore synchronisée (is_synced = 0)
    // 2. OU elle a été synchronisée APRÈS le timestamp du snapshot serveur
    final res = await db.query(
      'stock_exits',
      where: 'is_synced = 0 OR synced_at > ?',
      whereArgs: [serverTime],
    );
    return res.map((e) => StockExit.fromMap(e)).toList();
  }
}
