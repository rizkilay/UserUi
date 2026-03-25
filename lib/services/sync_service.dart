import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../database/product_dao.dart';

const String _baseUrl = 'https://backend-boutique.vercel.app';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final ProductDao _productDao = ProductDao();

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
}

