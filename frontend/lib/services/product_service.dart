import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'database_helper.dart';
import 'package:uuid/uuid.dart';

class ProductService {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  ProductService(this._apiService);

  Future<List<Product>> getProducts(String branchId) async {
    try {
      final response = await _apiService.get('/api/products/$branchId/list');
      if (response is Map && response.containsKey('products')) {
        final productsData = response['products'] as List;
        final branchName = response['branchName'] as String?;
        final products = productsData.map((json) {
          final productJson = Map<String, dynamic>.from(json);
          productJson['branchName'] = branchName;
          return Product.fromJson(productJson);
        }).toList();

        // Cache in local database for offline use (non-blocking)
        try {
          await _dbHelper.saveProducts(products);
        } catch (dbError) {
          debugPrint('SQLite cache failed (non-critical): $dbError');
        }
        return products;
      }
    } catch (e) {
      // If offline or error, try to get from local database
      try {
        final localProducts = await _dbHelper.getProducts(branchId);
        if (localProducts.isNotEmpty) {
          return localProducts;
        }
      } catch (dbError) {
        debugPrint('SQLite fallback failed: $dbError');
      }
      rethrow;
    }
    return [];
  }

  Future<List<Product>> getBusinessProducts(String businessId) async {
    try {
      final response = await _apiService.get('/api/products/business/$businessId/all');
      if (response is List) {
        return response.map((json) => Product.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Error loading business products: $e');
      rethrow;
    }
    return [];
  }

  // Get all products across all branches for a business (CEO)
  Future<List<Product>> getAllProductsForBusiness(List<String> branchIds) async {
    List<Product> allProducts = [];
    for (var branchId in branchIds) {
      try {
        final products = await getProducts(branchId);
        allProducts.addAll(products);
      } catch (e) {
        // Continue if one branch fails
        continue;
      }
    }
    return allProducts;
  }

  Future<Product> addProduct(Product product) async {
    try {
      final response = await _apiService.post(
        '/api/products/add',
        product.toJson(),
      );
      
      final newProduct = product.copyWith(
        id: response['productId'] ?? response['id'],
      );

      // Cache refresh (non-blocking — don't let SQLite errors break the flow)
      if (newProduct.branchId.isNotEmpty) {
        try {
          await getProducts(newProduct.branchId);
        } catch (e) {
          debugPrint('Cache refresh after add failed (non-critical): $e');
        }
      }
      return newProduct;
    } catch (e) {
      // Offline fallback — try to queue, but don't crash if SQLite fails too
      try {
        final tempId = const Uuid().v4();
        final offlineProduct = product.copyWith(id: tempId);
        await _dbHelper.queueProduct(offlineProduct, 'create');
        await _dbHelper.saveProducts([offlineProduct]);
        return offlineProduct;
      } catch (dbError) {
        debugPrint('Offline fallback also failed: $dbError');
        // Re-throw the original API error, not the SQLite error
        rethrow;
      }
    }
  }

  Future<void> updateProduct(String productId, Product product) async {
    try {
      await _apiService.put(
        '/api/products/$productId/update',
        product.toJson(),
      );
      // Update local cache (non-blocking)
      try {
        await _dbHelper.saveProducts([product]);
      } catch (dbError) {
        debugPrint('SQLite cache update failed (non-critical): $dbError');
      }
    } catch (e) {
      // Offline fallback
      try {
        await _dbHelper.queueProduct(product, 'update');
        await _dbHelper.saveProducts([product]);
      } catch (dbError) {
        debugPrint('Offline fallback failed: $dbError');
      }
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _apiService.delete('/api/products/$productId/delete');
    } catch (e) {
      try {
        await _dbHelper.queueProductDelete(productId);
        await _dbHelper.deleteProduct(productId);
      } catch (dbError) {
        debugPrint('Offline delete fallback failed: $dbError');
      }
      rethrow;
    }
  }

  Future<BarcodeProductInfo> lookupBarcode(String barcode) async {
    final response =
        await _apiService.get('/api/products/barcode/$barcode/lookup');
    return BarcodeProductInfo.fromJson(response as Map<String, dynamic>);
  }

  Future<Product> addProductFromBarcode(
    String branchId,
    String barcode,
    double? price,
    int stock,
  ) async {
    final params = {
      'barcode': barcode,
      'stock': stock.toString(),
    };
    if (price != null) {
      params['price'] = price.toString();
    }

    final response = await _apiService.postWithParams(
      '/api/products/$branchId/add-from-barcode',
      params,
    );
    // Need to fetch to get full product details
    final products = await getProducts(branchId);
    return products.firstWhere(
      (p) => (p.upc == barcode || p.ean13 == barcode),
      orElse: () => Product(
        id: response['productId'] ?? '',
        name: response['name'] ?? '',
        price: price ?? 0,
        stock: stock,
        branchId: branchId,
        upc: barcode.length == 12 ? barcode : null,
        ean13: barcode.length == 13 ? barcode : null,
      ),
    );
  }
}
