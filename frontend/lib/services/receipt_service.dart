import '../services/api_service.dart';
import '../models/business.dart';

class Receipt {
  final String id;
  final String description;
  final double amount;
  final String? supplier;
  final String recordedBy;
  final DateTime receiptDate;

  Receipt({
    required this.id,
    required this.description,
    required this.amount,
    this.supplier,
    required this.recordedBy,
    required this.receiptDate,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      supplier: json['supplier'],
      recordedBy: json['recordedBy'] ?? 'Unknown',
      receiptDate: DateTime.parse(json['receiptDate']),
    );
  }
}

class ReceiptService {
  final ApiService _apiService;

  ReceiptService(this._apiService);

  Future<void> addReceipt(String businessId, String description, double amount, String? supplier) async {
    await _apiService.post('/api/receipts/$businessId', {
      'description': description,
      'amount': amount,
      'supplier': supplier,
    });
  }

  Future<List<Receipt>> getReceipts(String businessId) async {
    final response = await _apiService.get('/api/receipts/$businessId');
    if (response is List) {
      return response.map((json) => Receipt.fromJson(json)).toList();
    }
    return [];
  }
}
