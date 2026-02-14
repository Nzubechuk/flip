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

        // Cache in local database for offline use
        await _dbHelper.saveProducts(products);
        return products;
      }
    } catch (e) {
      // If offline or error, try to get from local database
      final localProducts = await _dbHelper.getProducts(branchId);
      if (localProducts.isNotEmpty) {
        return localProducts;
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

      // If branchId is set, refresh that branch's list
      if (newProduct.branchId.isNotEmpty) {
         // efficient update: add to local cache if possible, or just fetch
         await getProducts(newProduct.branchId);
      }
      return newProduct;
    } catch (e) {
      // Offline fallback
      final tempId = const Uuid().v4();
      final offlineProduct = product.copyWith(id: tempId);
      await _dbHelper.queueProduct(offlineProduct, 'create');
      // Also save to local 'products' table so it appears in UI immediately?
      // Yes, otherwise user won't see it until sync.
      // But we need to distinguish it's offline? 
      // For now, just save it. The sync service handles the rest.
      // We might need to append it to the current cached list.
      // Since getProducts reads from DB, saving it to DB is enough.
      await _dbHelper.saveProducts([offlineProduct]);
      return offlineProduct;
    }
  }

  Future<void> updateProduct(String productId, Product product) async {
    try {
      await _apiService.put(
        '/api/products/$productId/update',
        product.toJson(),
      );
      // Update local cache
      await _dbHelper.saveProducts([product]);
    } catch (e) {
      // Offline fallback
      await _dbHelper.queueProduct(product, 'update');
      // Update local cache so user sees change
      await _dbHelper.saveProducts([product]);
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _apiService.delete('/api/products/$productId/delete');
      // Remove from local cache? DatabaseHelper doesn't have deleteProduct from cache yet,
      // only clearAll. We might need to add deleteProductFromCache.
      // For now, we rely on refresh. But offline we can't refresh.
      // TODO: Add deleteFromCache to DatabaseHelper
      // For now, we just queue it. The UI might still show it until sync.
    } catch (e) {
      await _dbHelper.queueProductDelete(productId);
      // Remove from local view immediately
      await _dbHelper.deleteProduct(productId);
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




