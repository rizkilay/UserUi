import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SyncMetadataDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> setValue(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'sync_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getValue(String key) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}
