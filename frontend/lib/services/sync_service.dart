import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'api_service.dart';
import 'sales_service.dart';
import 'debt_service.dart';
import '../models/sale.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService;
  final SalesService _salesService;
  final DebtService _debtService;
  bool _isSyncing = false;

  SyncService(this._apiService, this._salesService, this._debtService);

  bool get isSyncing => _isSyncing;

  Future<void> sync(String? businessId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint('Starting synchronization...');

    try {
      await _syncSales();
      if (businessId != null) {
        await _syncDebts(businessId);
      }
      debugPrint('Synchronization completed successfully.');
    } catch (e) {
      debugPrint('Error during synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSales() async {
    final pendingSales = await _dbHelper.getPendingSales();
    if (pendingSales.isEmpty) return;

    debugPrint('Syncing ${pendingSales.length} pending sales...');

    for (var saleMap in pendingSales) {
      try {
        final id = saleMap['id'] as int;
        final itemsJson = saleMap['itemsJson'] as String;
        final List<dynamic> itemsList = jsonDecode(itemsJson);
        final List<SaleItem> items = itemsList.map((i) => SaleItem(
          productId: '', // Not used in backend for finalization
          productCode: i['productCode'],
          name: i['name'],
          price: (i['price'] as num).toDouble(),
          quantity: i['quantity'] as int,
          subtotal: (i['price'] as num).toDouble() * (i['quantity'] as int),
          stock: 0, // Not needed here
        )).toList();

        await _salesService.finalizeSale(items);
        await _dbHelper.deletePendingSale(id);
        debugPrint('Sale $id synced and deleted from local queue.');
      } catch (e) {
        debugPrint('Failed to sync sale: $e');
        // Continue with next sale, don't stop everything
      }
    }
  }

  Future<void> _syncDebts(String businessId) async {
    final pendingDebts = await _dbHelper.getPendingDebts();
    if (pendingDebts.isEmpty) return;

    debugPrint('Syncing ${pendingDebts.length} pending debts...');

    for (var debtMap in pendingDebts) {
      try {
        final id = debtMap['id'] as int;
        final consumerName = debtMap['consumerName'] as String;
        final branchId = debtMap['branchId'] as String;
        final itemsJson = debtMap['itemsJson'] as String;
        final List<dynamic> itemsList = jsonDecode(itemsJson);
        
        // Convert to List<Map<String, dynamic>> as expected by DebtService
        final List<Map<String, dynamic>> items = itemsList.map((i) => {
          'productCode': i['productCode'],
          'name': i['name'],
          'quantity': i['quantity'] as int,
        }).toList();

        await _debtService.recordDebt(
          consumerName: consumerName,
          items: items,
          branchId: branchId,
          businessId: businessId,
        );
        await _dbHelper.deletePendingDebt(id);
        debugPrint('Debt $id synced and deleted from local queue.');
      } catch (e) {
        debugPrint('Failed to sync debt: $e');
      }
    }
  }
}
