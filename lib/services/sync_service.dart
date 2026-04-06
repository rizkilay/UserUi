import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../database/product_dao.dart';
import '../database/exit_dao.dart';
import '../database/expense_dao.dart';
import '../database/cotisation_dao.dart';
import '../database/sync_metadata_dao.dart';
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
  final SyncMetadataDao _metadataDao = SyncMetadataDao();

  /// Fetches products from the backend incrementally and stores them locally.
  Future<List<ProductModel>> fetchAndSyncProducts() async {
    try {
      final String? lastSync = await _metadataDao.getValue('last_products_sync');
      final uri = Uri.parse('$_baseUrl/api/products').replace(
        queryParameters: lastSync != null ? {'since': lastSync} : null,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> productsJson = responseData['products'] ?? [];
        final String? serverTime = responseData['server_time'];

        if (productsJson.isEmpty) {
          debugPrint('SyncService: No new product updates');
          return await _loadLocal();
        }

        // 1. Get all sales that should be subtracted from server quantity
        // This includes unsynced sales AND recently synced sales not yet in server snapshot
        final localSales = await _exitDao.getSalesNotYetOnServer(serverTime);
        final Map<int, int> localQuantities = {};
        for (var exit in localSales) {
          localQuantities[exit.productId] = (localQuantities[exit.productId] ?? 0) + exit.quantity;
        }

        final List<ProductModel> products = [];
        for (var json in productsJson) {
          var product = ProductModel.fromJson(json);

          // 2. Conflict Resolution: Adjust quantity based on local sales protection
          if (localQuantities.containsKey(product.id) && product.quantity != null) {
            int localImpact = localQuantities[product.id]!;
            int adjustedQty = product.quantity! - localImpact;
            if (adjustedQty < 0) adjustedQty = 0;

            product = ProductModel(
              id: product.id,
              image: product.image,
              brandName: product.brandName,
              title: product.title,
              price: product.price,
              priceAfetDiscount: product.priceAfetDiscount,
              dicountpercent: product.dicountpercent,
              quantity: adjustedQty,
              category: product.category,
              description: product.description,
            );
          }
          products.add(product);
        }

        // 3. Persist locally
        await _productDao.insertAll(products);

        // 4. Update last sync time
        if (serverTime != null) {
          await _metadataDao.setValue('last_products_sync', serverTime);
        }

        debugPrint('SyncService: ${products.length} products updated incrementally');
        return await _loadLocal();
      } else {
        debugPrint('SyncService: Backend error ${response.statusCode}, loading from local DB');
        return await _loadLocal();
      }
    } catch (e) {
      debugPrint('SyncService: Error during incremental sync ($e), loading from local DB');
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
        final pushTime = DateTime.now().toIso8601String();
        final res = await http.post(
          Uri.parse('$_baseUrl/api/sync-exits'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(unsyncedExits.map((e) => e.toMap()).toList()),
        );
        if (res.statusCode == 200) {
          await _exitDao.markAsSyncedWithTimestamp(
            unsyncedExits.map((e) => e.id!).toList(),
            pushTime,
          );
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

