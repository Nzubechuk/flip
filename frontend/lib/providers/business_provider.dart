import 'package:flutter/foundation.dart';
import '../models/debt.dart';
import '../models/business.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../services/business_service.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';
import '../services/debt_service.dart';
import '../services/analytics_service.dart';
import '../services/sales_service.dart';
import '../models/sale.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessService _businessService;
  final ProductService _productService;
  final DebtService _debtService;
  final AnalyticsService _analyticsService;
  final ApiService _apiService;
  final SalesService _salesService;
  
  
  Business? _business;
  List<Branch> _branches = [];
  List<User> _managers = [];
  List<User> _clerks = [];
  List<Product> _allProducts = [];
  List<Debt> _debts = [];
  double _totalDebtsAmount = 0.0;
  double _dailySalesTotal = 0.0;
  bool _isBranchesLoading = false;
  bool _isManagersLoading = false;
  bool _isProductsLoading = false;
  bool _isDebtsLoading = false;
  bool _isAnalyticsLoading = false;
  String? _errorMessage;

  BusinessProvider(this._businessService, this._productService, this._debtService, this._analyticsService, this._apiService, this._salesService);

  Business? get business => _business;
  List<Branch> get branches => _branches;
  List<User> get managers => _managers;
  List<User> get clerks => _clerks;
  List<Product> get allProducts => _allProducts;
  List<Debt> get debts => _debts;
  double get totalDebtsAmount => _totalDebtsAmount;
  double get dailySalesTotal => _dailySalesTotal;
  bool get isLoading => _isBranchesLoading || _isManagersLoading || _isProductsLoading || _isDebtsLoading || _isAnalyticsLoading;
  bool get isBranchesLoading => _isBranchesLoading;
  bool get isManagersLoading => _isManagersLoading;
  bool get isProductsLoading => _isProductsLoading;
  bool get isDebtsLoading => _isDebtsLoading;
  bool get isAnalyticsLoading => _isAnalyticsLoading;
  String? get errorMessage => _errorMessage;

  // Get business ID - will be set after loading business info
  String? get businessId => _business?.id;

  Future<void> loadBusinessData(String businessId) async {
    _isBranchesLoading = true;
    _isManagersLoading = true;
    _isProductsLoading = true;
    _isDebtsLoading = true;
    _isAnalyticsLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Start all loads in parallel
    final branchesFuture = _loadBranches(businessId);
    final peopleFuture = _loadManagersAndClerks(businessId);
    final productsFuture = _loadProducts(businessId);
    final debtsFuture = _loadDebts(businessId);
    final analyticsFuture = _loadAnalytics(businessId);

    // We don't await Future.wait because we want notifyListeners to fire as each completes
    await Future.wait([
      branchesFuture,
      peopleFuture,
      productsFuture,
      debtsFuture,
      analyticsFuture,
    ]);
  }

  Future<void> _loadBranches(String businessId) async {
    _isBranchesLoading = true;
    notifyListeners();
    try {
      _branches = await _businessService.getBranches(businessId);
    } catch (e) {
      debugPrint('Error loading branches: $e');
    } finally {
      _isBranchesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadManagersAndClerks(String businessId) async {
    _isManagersLoading = true;
    notifyListeners();
    try {
      _managers = await _businessService.getManagers(businessId);
      _clerks = await _businessService.getClerks(businessId);
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      _isManagersLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProducts(String businessId) async {
    _isProductsLoading = true;
    notifyListeners();
    try {
      _allProducts = await _productService.getBusinessProducts(businessId);
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isProductsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDebts(String businessId) async {
    _isDebtsLoading = true;
    notifyListeners();
    try {
      final debts = await _debtService.getDebtsByBusiness(businessId);
      _debts = debts;
      _totalDebtsAmount = debts.fold(0.0, (sum, d) => sum + d.totalAmount);
    } catch (e) {
      debugPrint('Error loading debts: $e');
    } finally {
      _isDebtsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAnalytics(String businessId) async {
    _isAnalyticsLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      _dailySalesTotal = await _analyticsService.getTotalRevenue(now, now.add(const Duration(days: 1)));
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      _isAnalyticsLoading = false;
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

  List<Debt> getDebtsForDate(DateTime date) {
    return _debts.where((debt) {
      return debt.createdAt.year == date.year &&
             debt.createdAt.month == date.month &&
             debt.createdAt.day == date.day;
    }).toList();
  }

  // Reactive Update Methods

  Future<void> createProduct(Product product) async {
    try {
      final newProduct = await _productService.addProduct(product);
      _allProducts.add(newProduct);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createBranch(String name, String? location, String? managerId) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      final newBranch = await _businessService.createBranch(_business!.id, name, location, managerId);
      _branches.add(newBranch);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<Sale> processSale(List<SaleItem> items, String? branchId) async {
    try {
      // Calculate total for local update
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.subtotal);
      
      final sale = await _salesService.finalizeSale(items);
      
      // Update daily sales local state
      _dailySalesTotal += totalAmount;

      // Update local product stock
      // Note: This only updates the list in memory. 
      // Ideally we should match products by ID and update stock.
      for (var item in items) {
        final index = _allProducts.indexWhere((p) => p.id == item.productId);
        if (index != -1) {
          final product = _allProducts[index];
          // Determine new stock
          final newStock = product.stock - item.quantity;
          _allProducts[index] = product.copyWith(stock: newStock >= 0 ? newStock : 0);
        }
      }
      
      notifyListeners();
      return sale;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _productService.updateProduct(product.id, product);
      final index = _allProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _allProducts[index] = product;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      _allProducts.removeWhere((p) => p.id == productId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBranch(String branchId, String name, String? location) async {
    if (_business?.id == null) return;
    try {
      await _businessService.updateBranch(_business!.id, branchId, name, location);
      final index = _branches.indexWhere((b) => b.id == branchId);
      if (index != -1) {
        _branches[index] = _branches[index].copyWith(name: name, location: location);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBranch(String branchId) async {
    if (_business?.id == null) return;
    try {
      await _businessService.deleteBranch(_business!.id, branchId);
      _branches.removeWhere((b) => b.id == branchId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  Future<void> createManager(String username, String password, String firstName, String lastName, String email, String? branchId) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      final newUser = await _businessService.registerManager(
        _business!.id,
        username,
        password,
        firstName,
        lastName,
        email,
        branchId,
      );
      _managers.add(newUser);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createClerk(String username, String password, String firstName, String lastName, String email, String? branchId) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      final newUser = await _businessService.registerClerk(
        _business!.id,
        username,
        password,
        firstName,
        lastName,
        email,
        branchId,
      );
      _clerks.add(newUser);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateManagerData(
    String managerId,
    String username,
    String? password,
    String? firstName,
    String? lastName,
    String? email,
  ) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      await _businessService.updateManager(
        _business!.id,
        managerId,
        username,
        password,
        firstName,
        lastName,
        email,
      );
      
      final index = _managers.indexWhere((m) => m.userId == managerId);
      if (index != -1) {
        final current = _managers[index];
        _managers[index] = User(
          userId: current.userId,
          username: username,
          firstName: firstName ?? current.firstName,
          lastName: lastName ?? current.lastName,
          email: email ?? current.email,
          role: current.role,
          businessId: current.businessId,
          branchId: current.branchId, // Branch update not supported in this API call
          branchName: current.branchName,
        );
        notifyListeners();
      } else {
        // Fallback if not found locally
        await refreshManagers();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClerkData(
    String clerkId,
    String username,
    String? password,
    String? firstName,
    String? lastName,
    String? email,
  ) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      await _businessService.updateClerk(
        _business!.id,
        clerkId,
        username,
        password,
        firstName,
        lastName,
        email,
      );
      
      final index = _clerks.indexWhere((c) => c.userId == clerkId);
      if (index != -1) {
        final current = _clerks[index];
        _clerks[index] = User(
          userId: current.userId,
          username: username,
          firstName: firstName ?? current.firstName,
          lastName: lastName ?? current.lastName,
          email: email ?? current.email,
          role: current.role,
          businessId: current.businessId,
          branchId: current.branchId,
          branchName: current.branchName,
        );
        notifyListeners();
      } else {
         await refreshClerks();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteManagerData(String managerId) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      await _businessService.deleteManager(_business!.id, managerId);
      _managers.removeWhere((m) => m.userId == managerId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteClerkData(String clerkId) async {
    if (_business?.id == null) throw Exception('Business ID not found');
    try {
      await _businessService.deleteClerk(_business!.id, clerkId);
      _clerks.removeWhere((c) => c.userId == clerkId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

