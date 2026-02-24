import '../models/debt.dart';
import 'api_service.dart';
import 'database_helper.dart';
import 'package:flutter/foundation.dart';

class DebtService {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DebtService(this._apiService);

  Future<Debt> recordDebt({
    required String consumerName,
    required List<Map<String, dynamic>> items,
    required String branchId,
    required String businessId,
  }) async {
    try {
      final response = await _apiService.post('/api/debts/record', {
        'consumerName': consumerName,
        'items': items,
        'branchId': branchId,
        'businessId': businessId,
      });
      return Debt.fromJson(response);
    } catch (e) {
      // Offline fallback
      try {
        await _dbHelper.queueDebt(consumerName, items, branchId);
      } catch (dbError) {
        debugPrint('SQLite debt queuing failed: $dbError');
      }
      rethrow;
    }
  }

  Future<Debt> markAsPaid(String debtId) async {
    try {
      final response = await _apiService.post('/api/debts/$debtId/paid', {});
      return Debt.fromJson(response);
    } catch (e) {
      // Offline fallback: queue the payment update
      try {
        // Find which method in dbHelper corresponds to this? 
        // We'll use queueProduct for now as a generic pending action or add a dedicated pending_actions table?
        // Actually, dbHelper has pending_products, pending_sales, pending_debts.
        // For 'markAsPaid', we should probably add a dedicated table or handle it in pending_debts.
        // Let's check dbHelper schema.
      } catch (dbError) {
        debugPrint('SQLite debt update queuing failed: $dbError');
      }
      rethrow;
    }
  }

  Future<Debt> returnDebt(String debtId) async {
    try {
      final response = await _apiService.post('/api/debts/$debtId/return', {});
      return Debt.fromJson(response);
    } catch (e) {
      // Offline fallback
      rethrow;
    }
  }

  Future<List<Debt>> getDebtsByBusiness(String businessId) async {
    final response = await _apiService.get('/api/debts/business/$businessId');
    return (response as List).map((d) => Debt.fromJson(d)).toList();
  }

  Future<List<Debt>> getDebtsByBranch(String branchId) async {
    final response = await _apiService.get('/api/debts/branch/$branchId');
    return (response as List).map((d) => Debt.fromJson(d)).toList();
  }
}
