import '../models/debt.dart';
import 'api_service.dart';

class DebtService {
  final ApiService _apiService;

  DebtService(this._apiService);

  Future<Debt> recordDebt({
    required String consumerName,
    required List<Map<String, dynamic>> items,
    required String branchId,
    required String businessId,
  }) async {
    final response = await _apiService.post('/api/debts/record', {
      'consumerName': consumerName,
      'items': items,
      'branchId': branchId,
      'businessId': businessId,
    });
    return Debt.fromJson(response);
  }

  Future<Debt> markAsPaid(String debtId) async {
    final response = await _apiService.post('/api/debts/$debtId/paid', {});
    return Debt.fromJson(response);
  }

  Future<Debt> returnDebt(String debtId) async {
    final response = await _apiService.post('/api/debts/$debtId/return', {});
    return Debt.fromJson(response);
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
