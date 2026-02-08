import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import 'connectivity_provider.dart';

class SyncProvider with ChangeNotifier {
  final SyncService _syncService;
  bool _isSyncing = false;

  SyncProvider(this._syncService);

  bool get isSyncing => _isSyncing;

  Future<void> sync(String? businessId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    
    await _syncService.sync(businessId);
    
    _isSyncing = false;
    notifyListeners();
  }
}
