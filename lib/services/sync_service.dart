import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../database/product_dao.dart';
import '../database/exit_dao.dart';
import '../database/expense_dao.dart';
import '../database/cotisation_dao.dart';
import '../models/stock_exit.dart';
import '../models/expense.dart';
import '../models/cotisation.dart';

const String _baseUrl = 'https://backend-boutique.vercel.app';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final ProductDao _productDao = ProductDao();
  final ExitDao _exitDao = ExitDao();
  final ExpenseDao _expenseDao = ExpenseDao();
  final CotisationDao _cotisationDao = CotisationDao();

  /// Fetches products from the backend and stores them locally.
  /// Returns the list of products (from local DB after sync, or local if offline).
  Future<List<ProductModel>> fetchAndSyncProducts() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/products'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final products = data.map((e) => ProductModel.fromJson(e)).toList();

        // Persist locally
        await _productDao.insertAll(products);

        debugPrint('SyncService: ${products.length} products synced from backend');
        return products;
      } else {
        debugPrint('SyncService: Backend error ${response.statusCode}, loading from local DB');
        return await _loadLocal();
      }
    } catch (e) {
      debugPrint('SyncService: offline or error ($e), loading from local DB');
      return await _loadLocal();
    }
  }

  Future<List<ProductModel>> getLocalProducts() async {
    return await _loadLocal();
  }

  Future<List<ProductModel>> _loadLocal() async {
    return await _productDao.getAll();
  }

  /// Pushes all unsynced local data to the backend and pulls products.
  Future<bool> syncAll() async {
    try {
      bool success = true;

      // 1. Push Sales (Exits)
      final unsyncedExits = await _exitDao.getUnsynced();
      if (unsyncedExits.isNotEmpty) {
        final res = await http.post(
          Uri.parse('$_baseUrl/api/sync-exits'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(unsyncedExits.map((e) => e.toMap()).toList()),
        );
        if (res.statusCode == 200) {
          await _exitDao.markAsSynced(unsyncedExits.map((e) => e.id!).toList());
        } else {
          success = false;
        }
      }

      // 2. Push Expenses
      final unsyncedExpenses = await _expenseDao.getUnsynced();
      if (unsyncedExpenses.isNotEmpty) {
        final res = await http.post(
          Uri.parse('$_baseUrl/api/sync-expenses'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(unsyncedExpenses.map((e) => e.toMap()).toList()),
        );
        if (res.statusCode == 200) {
          await _expenseDao.markAsSynced(unsyncedExpenses.map((e) => e.id!).toList());
        } else {
          success = false;
        }
      }

      // 3. Push Cotisations
      final unsyncedCotisations = await _cotisationDao.getUnsynced();
      if (unsyncedCotisations.isNotEmpty) {
        final res = await http.post(
          Uri.parse('$_baseUrl/api/sync-cotisations'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(unsyncedCotisations.map((c) => c.toMap()).toList()),
        );
        if (res.statusCode == 200) {
          await _cotisationDao.markAsSynced(unsyncedCotisations.map((c) => c.id!).toList());
        } else {
          success = false;
        }
      }

      // 4. Pull Products
      await fetchAndSyncProducts();

      return success;
    } catch (e) {
      debugPrint('SyncService: Error during syncAll ($e)');
      return false;
    }
  }
}

