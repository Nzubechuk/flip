import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService;

  AnalyticsService(this._apiService);

  Future<double> getTotalRevenue(DateTime startDate, DateTime endDate, {String? branchId}) async {
    String url = '/api/analytics/sales/revenue?startDate=${startDate.toIso8601String().split('T')[0]}&endDate=${endDate.toIso8601String().split('T')[0]}';
    if (branchId != null) url += '&branchId=$branchId';
    
    final response = await _apiService.get(url);
    if (response is num) return response.toDouble();
    if (response is String) return double.tryParse(response) ?? 0.0;
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    DateTime startDate,
    DateTime endDate, {
    String? branchId,
  }) async {
    String url = '/api/analytics/sales/transactions?startDate=${startDate.toIso8601String().split('T')[0]}&endDate=${endDate.toIso8601String().split('T')[0]}';
    if (branchId != null) url += '&branchId=$branchId';

    final response = await _apiService.get(url);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getBestSellingProducts(
    DateTime startDate,
    DateTime endDate, {
    String? branchId,
  }) async {
    String url = '/api/analytics/sales/best-selling?startDate=${startDate.toIso8601String().split('T')[0]}&endDate=${endDate.toIso8601String().split('T')[0]}';
    if (branchId != null) url += '&branchId=$branchId';

    final response = await _apiService.get(url);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts(int threshold, {String? branchId}) async {
    String url = '/api/analytics/products/low-stock?threshold=$threshold';
    if (branchId != null) url += '&branchId=$branchId';

    final response = await _apiService.get(url);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMostStockedProducts({String? branchId}) async {
    String url = '/api/analytics/products/most-stocked';
    if (branchId != null) url += '?branchId=$branchId';
    else url += '';

    final response = await _apiService.get(url);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
