import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/product_model.dart';

class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAll(List<ProductModel> products) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var p in products) {
      batch.insert('products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((m) => ProductModel.fromJson(m)).toList();
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('products');
  }
}
