import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../services/business_service.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';
import '../services/debt_service.dart';
import '../services/analytics_service.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessService _businessService;
  final ProductService _productService;
  final DebtService _debtService;
  final AnalyticsService _analyticsService;
  final ApiService _apiService;
  
  
  Business? _business;
  List<Branch> _branches = [];
  List<User> _managers = [];
  List<User> _clerks = [];
  List<Product> _allProducts = [];
  double _totalDebtsAmount = 0.0;
  double _dailySalesTotal = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  BusinessProvider(this._businessService, this._productService, this._debtService, this._analyticsService, this._apiService);

  Business? get business => _business;
  List<Branch> get branches => _branches;
  List<User> get managers => _managers;
  List<User> get clerks => _clerks;
  List<Product> get allProducts => _allProducts;
  double get totalDebtsAmount => _totalDebtsAmount;
  double get dailySalesTotal => _dailySalesTotal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get business ID - will be set after loading business info
  String? get businessId => _business?.id;

  Future<void> loadBusinessData(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load branches
      _branches = await _businessService.getBranches(businessId);
      
      // Load managers and clerks
      _managers = await _businessService.getManagers(businessId);
      _clerks = await _businessService.getClerks(businessId);

      // Load all products for the business (includes global products and all branches)
      _allProducts = await _productService.getBusinessProducts(businessId);

      // Load debts
      if (_apiService.accessToken != null) {
        // Ensure tokens are synced if needed, but ApiService is shared in main.dart
      }
      final debts = await _debtService.getDebtsByBusiness(businessId);
      _totalDebtsAmount = debts.fold(0.0, (sum, d) => sum + d.totalAmount);

      // Load daily sales
      final now = DateTime.now();
      // Using same start/end date gets sales for that specific day
      _dailySalesTotal = await _analyticsService.getTotalRevenue(now, now); // Global for business

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_business?.id != null) {
      await loadBusinessData(_business!.id);
    }
  }

  Future<void> refreshBranches() async {
    if (_business?.id == null) return;
    try {
      _branches = await _businessService.getBranches(_business!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing branches: $e');
    }
  }

  Future<void> refreshManagers() async {
    if (_business?.id == null) return;
    try {
      _managers = await _businessService.getManagers(_business!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing managers: $e');
    }
  }

  Future<void> refreshClerks() async {
    if (_business?.id == null) return;
    try {
      _clerks = await _businessService.getClerks(_business!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing clerks: $e');
    }
  }

  Future<void> refreshAllProducts() async {
    if (_business?.id == null) return;
    try {
      _allProducts = await _productService.getBusinessProducts(_business!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing products: $e');
    }
  }

  void setBusiness(Business business) {
    _business = business;
    notifyListeners();
  }

  void addManager(User manager) {
    if (!_managers.any((m) => m.userId == manager.userId)) {
      _managers.add(manager);
      notifyListeners();
    }
  }

  void addClerk(User clerk) {
    if (!_clerks.any((c) => c.userId == clerk.userId)) {
      _clerks.add(clerk);
      notifyListeners();
    }
  }

  void removeProduct(String productId) {
    _allProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void removeManager(String managerId) {
    _managers.removeWhere((m) => m.userId == managerId);
    notifyListeners();
  }

  void removeClerk(String clerkId) {
    _clerks.removeWhere((c) => c.userId == clerkId);
    notifyListeners();
  }

  void updateManager(User updatedManager) {
    final index = _managers.indexWhere((m) => m.userId == updatedManager.userId);
    if (index != -1) {
      _managers[index] = updatedManager;
      notifyListeners();
    }
  }

  void updateClerk(User updatedClerk) {
    final index = _clerks.indexWhere((c) => c.userId == updatedClerk.userId);
    if (index != -1) {
      _clerks[index] = updatedClerk;
      notifyListeners();
    }
  }
}

