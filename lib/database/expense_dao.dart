import '../models/expense.dart';
import 'database_helper.dart';

class ExpenseDao {
  Future<int> insert(Expense expense) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('expenses', orderBy: 'datetime DESC');
    return res.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getByCategory(String category) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'datetime DESC',
    );
    return res.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'expenses',
      where: 'datetime BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'datetime DESC',
    );
    return res.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> update(Expense expense) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalByCategory(String category) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE category = ?',
      [category],
    );
    final v = result.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<double> getTotalByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE datetime BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final v = result.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<double> getTotalBySource(String source) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE source = ?',
      [source],
    );
    final v = result.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }
}
