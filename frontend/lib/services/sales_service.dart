import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'api_service.dart';
import 'database_helper.dart';

class SalesService {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SalesService(this._apiService);

  Future<Product> scanProduct(String productCode, int quantity) async {
    try {
      final request = ScannedProductRequest(
        productCode: productCode,
        quantity: quantity,
      );
      final response = await _apiService.post(
        '/api/sales/scan',
        request.toJson(),
      );
      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Offline fallback: check local database
      final localProduct = await _dbHelper.getProductByCode(productCode);
      if (localProduct != null) {
        // Return local product if found
        return localProduct;
      }
      rethrow;
    }
  }

  Future<Sale> finalizeSale(List<SaleItem> items) async {
    try {
      final request = SaleRequest(items: items);
      final response = await _apiService.post(
        '/api/sales/finalize',
        request.toJson(),
      );
      return Sale.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Offline fallback: queue the sale
      try {
        // Assume shared branch ID from the first product or business default
        // In POS, we usually have a branchId context. 
        // For now, if we can't find it, we pass empty string and let sync handle it.
        await _dbHelper.queueSale(items.map((i) => i.toJson()).toList(), '');
      } catch (dbError) {
        debugPrint('SQLite sale queuing failed: $dbError');
      }
      rethrow;
    }
  }
}




