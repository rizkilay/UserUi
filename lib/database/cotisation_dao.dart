import '../models/cotisation.dart';
import '../models/cotisation_withdrawal.dart';
import 'database_helper.dart';

class CotisationDao {
  Future<int> insert(Cotisation cotisation) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('cotisations', cotisation.toMap());
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('cotisations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(Cotisation cotisation) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'cotisations',
      cotisation.toMap(),
      where: 'id = ?',
      whereArgs: [cotisation.id],
    );
  }

  Future<List<Cotisation>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('cotisations', orderBy: 'id DESC');
    final List<Cotisation> list = [];

    for (var row in res) {
      final id = row['id'] as int;
      final amount = (row['amount'] as num).toDouble();

      final wRes = await db.rawQuery(
        'SELECT IFNULL(SUM(amount),0) as total FROM cotisation_withdrawals WHERE cotisation_id = ?',
        [id],
      );
      final wVal = wRes.first['total'];
      double withdrawn = 0.0;
      if (wVal is int) withdrawn = wVal.toDouble();
      else if (wVal is double) withdrawn = wVal;

      final remaining = (amount - withdrawn) < 0 ? 0.0 : (amount - withdrawn);
      final isWithdrawn = remaining <= 0.0;

      list.add(Cotisation(
        id: id,
        amount: amount,
        date: (row['date'] as String?) ?? DateTime.now().toIso8601String(),
        note: row['note'] as String?,
        source: (row['source'] as String?) ?? 'caisse',
        category: row['category'] as String?,
        partnerId: row['partner_id'] as int?,
        remaining: remaining,
        isWithdrawn: isWithdrawn,
      ));
    }
    return list;
  }

  Future<double> getTotalAmount() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT (IFNULL((SELECT SUM(amount) FROM cotisations),0)
             - IFNULL((SELECT SUM(amount) FROM cotisation_withdrawals),0)) as total
    ''');
    final v = res.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<double> getTotalAmountBySource(String source) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT (
        IFNULL((SELECT SUM(amount) FROM cotisations WHERE source = ?),0)
        - IFNULL((SELECT SUM(w.amount) FROM cotisation_withdrawals w
                  JOIN cotisations c ON w.cotisation_id = c.id WHERE c.source = ?),0)
      ) as total
    ''', [source, source]);
    final v = res.first['total'];
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    return v as double;
  }

  Future<Map<int, double>> getPartnerContributions() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT c.partner_id as partner_id,
             (IFNULL(SUM(c.amount),0) - IFNULL(SUM(w.total_withdrawn),0)) as total
      FROM cotisations c
      LEFT JOIN (
        SELECT cotisation_id, SUM(amount) as total_withdrawn
        FROM cotisation_withdrawals GROUP BY cotisation_id
      ) w ON c.id = w.cotisation_id
      WHERE c.source = ? AND c.partner_id IS NOT NULL
      GROUP BY c.partner_id
    ''', ['partner']);

    final Map<int, double> contributions = {};
    for (var row in res) {
      final val = row['total'];
      double d = 0.0;
      if (val is int) d = val.toDouble();
      else if (val is double) d = val;
      contributions[row['partner_id'] as int] = d;
    }
    return contributions;
  }

  Future<double> withdrawAmount(double amountRequested, String source, String motif) async {
    final db = await DatabaseHelper.instance.database;

    final availRes = await db.rawQuery('''
      SELECT (
        IFNULL((SELECT SUM(amount) FROM cotisations WHERE source = ?),0)
        - IFNULL((SELECT SUM(w.amount) FROM cotisation_withdrawals w
                  JOIN cotisations c ON w.cotisation_id = c.id WHERE c.source = ?),0)
      ) as total
    ''', [source, source]);

    final availVal = availRes.first['total'];
    double available = 0.0;
    if (availVal is int) available = availVal.toDouble();
    else if (availVal is double) available = availVal;

    if (available <= 0) return 0.0;
    if (amountRequested > available) return -1.0;

    double remaining = amountRequested;
    final cotRows = await db.query('cotisations',
        where: 'source = ?', whereArgs: [source], orderBy: 'id ASC');

    for (var cot in cotRows) {
      if (remaining <= 0) break;
      final cotId = cot['id'] as int;
      final cotAmount = (cot['amount'] as num).toDouble();

      final wRes = await db.rawQuery(
        'SELECT IFNULL(SUM(amount),0) as total FROM cotisation_withdrawals WHERE cotisation_id = ?',
        [cotId],
      );
      final wVal = wRes.first['total'];
      double already = 0.0;
      if (wVal is int) already = wVal.toDouble();
      else if (wVal is double) already = wVal;

      final availableForCot = cotAmount - already;
      if (availableForCot <= 0) continue;

      final take = availableForCot >= remaining ? remaining : availableForCot;
      await db.insert('cotisation_withdrawals', {
        'cotisation_id': cotId,
        'amount': take,
        'date': DateTime.now().toIso8601String(),
        'motif': motif,
        'source': source,
      });
      remaining -= take;
    }

    return amountRequested - remaining;
  }

  Future<List<CotisationWithdrawal>> getWithdrawals({int? cotisationId}) async {
    final db = await DatabaseHelper.instance.database;
    String where = '';
    List<dynamic> args = [];
    if (cotisationId != null) {
      where = 'WHERE cotisation_id = ?';
      args = [cotisationId];
    }
    final res = await db.rawQuery(
      'SELECT * FROM cotisation_withdrawals $where ORDER BY date DESC',
      args,
    );
    return res.map((r) => CotisationWithdrawal.fromMap(r)).toList();
  }
}
