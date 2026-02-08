import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'database_helper.dart';

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
    // Branch ID is now optional/included in product
    final response = await _apiService.post(
      '/api/products/add',
      product.toJson(),
    );
    // Refresh list based on whether a branch was used or not?
    // If branchId is null (Global product), might not appear in standard branch list
    // But for return value, we trust the response or just return input
    // Ideally we should list again, but which list?
    // For now, return product.
    // If branchId is set, we can refresh that branch's specific list
    if (product.branchId.isNotEmpty) {
       await getProducts(product.branchId);
    }
    return product;
  }

  Future<void> updateProduct(String productId, Product product) async {
    await _apiService.put(
      '/api/products/$productId/update',
      product.toJson(),
    );
  }

  Future<void> deleteProduct(String productId) async {
    await _apiService.delete('/api/products/$productId/delete');
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




