import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../models/user.dart';
import '../../../services/sales_service.dart';
import '../../../services/api_service.dart';
import '../../../models/sale.dart';
import '../../../models/business.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../services/database_helper.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/ui_helper.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/responsive_helper.dart';

class PosScreen extends StatefulWidget {
  final String? branchId;
  const PosScreen({super.key, this.branchId});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<SaleItem> _cart = [];
  final _barcodeController = TextEditingController();
  double _total = 0.0;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    if (widget.branchId != null) {
      _selectedBranchId = widget.branchId;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    _total = _cart.fold(0.0, (sum, item) => sum + item.subtotal);
    setState(() {});
  }

  Future<void> _scanProduct(String barcode) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final salesService = SalesService(apiService);

      final product = await salesService.scanProduct(barcode, 1);

      if (!mounted) return;

      // Use productCode, UPC, or EAN-13 as identifier
      final productCode = product.productCode ?? product.upc ?? product.ean13 ?? product.id;
      
      // Add to cart - match by productCode if available
      final existingIndex = productCode != product.id
          ? _cart.indexWhere((item) => item.productCode == productCode)
          : _cart.indexWhere((item) => item.productId == product.id);

      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        _cart[existingIndex] = SaleItem(
          productId: existing.productId,
          productCode: existing.productCode ?? productCode,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
          subtotal: existing.price * (existing.quantity + 1),
          stock: existing.stock,
        );
      } else {
        _cart.add(SaleItem(
          productId: product.id,
          productCode: productCode,
          name: product.name,
          price: product.price,
          quantity: 1,
          subtotal: product.price,
          stock: product.stock,
        ));
      }

      _barcodeController.clear();
      _calculateTotal();
    } catch (e) {
      if (!mounted) return;
      UiHelper.showError(context, ErrorHandler.formatException(e));
    }
  }

  Future<void> _selectBranchForSale() async {
    final businessProvider = context.read<BusinessProvider>();
    final branches = businessProvider.branches;
    final authProvider = context.read<AuthProvider>();
    
    // For CLERK or MANAGER, use their assigned branch
    if (widget.branchId != null) {
      _selectedBranchId = widget.branchId;
      _finalizeSale();
      return;
    }

    if ((authProvider.user?.role == UserRole.clerk || authProvider.user?.role == UserRole.manager) && 
        authProvider.user?.branchId != null) {
      _selectedBranchId = authProvider.user!.branchId;
      _finalizeSale();
      return;
    }
    
    // For CEO, show branch selection dialog
    if (branches.isEmpty) {
      UiHelper.showError(context, 'No branches available');
      return;
    }
    
    final selectedBranch = await showDialog<Branch>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Branch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branch = branches[index];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(branch.name),
                subtitle: Text(branch.location ?? ''),
                onTap: () => Navigator.pop(context, branch),
              );
            },
          ),
        ),
      ),
    );
    
    if (selectedBranch != null) {
      setState(() {
        _selectedBranchId = selectedBranch.id;
      });
      _finalizeSale();
    }
  }
  Future<void> _finalizeSale() async {
    if (_cart.isEmpty) {
      UiHelper.showInfo(context, 'Cart is empty');
      return;
    }

    // Validate stock before finalizing
    for (var item in _cart) {
      if (item.quantity > item.stock) {
        UiHelper.showError(context, 'Insufficient stock for ${item.name}. Available: ${item.stock}');
        return;
      }
    }

    if (_selectedBranchId == null) {
      _selectBranchForSale();
      return;
    }

    final connectivity = context.read<ConnectivityProvider>();
    if (connectivity.isOffline) {
      await _queueSaleLocally();
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final salesService = SalesService(apiService);

      final sale = await salesService.finalizeSale(_cart);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sale Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${CurrencyFormatter.format(sale.totalPrice)}'),
              const SizedBox(height: 8),
              Text('Items: ${sale.items.length}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _cart.clear();
                _total = 0.0;
                _selectedBranchId = null;
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('New Sale'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // If network fails during call, try to queue locally
      await _queueSaleLocally();
    }
  }

  Future<void> _queueSaleLocally() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.queueSale(_cart, _selectedBranchId!);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Offline Mode'),
            ],
          ),
          content: const Text('Connection is unstable. The sale has been saved locally and will be synchronized automatically once your internet is stable.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cart.clear();
                  _total = 0.0;
                });
                Navigator.pop(context);
              },
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    } catch (e) {
      UiHelper.showError(context, 'Failed to queue sale: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final authProvider = context.watch<AuthProvider>();
    final branches = businessProvider.branches;
    
    // For CEO, show branch selector if no branch selected
    final showBranchSelector = authProvider.user?.role == UserRole.ceo && 
                               _selectedBranchId == null && 
                               branches.isNotEmpty;

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          // Offline Indicator
          if (context.watch<ConnectivityProvider>().isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Colors.orange.shade700,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Working Offline',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          
          if (isMobile)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBranchSelector(authProvider, branches, showBranchSelector),
                    _buildBarcodeScanner(authProvider),
                    _buildCart(authProvider),
                    _buildCheckoutSection(authProvider),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Scanner and Cart
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildBranchSelector(authProvider, branches, showBranchSelector),
                        _buildBarcodeScanner(authProvider),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildCart(authProvider),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side: Summary and Checkout
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sale Summary',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 32),
                                  _buildSummaryRow('Items', _cart.length.toString()),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow('Total Quantity', _cart.fold(0, (sum, item) => sum + item.quantity).toString()),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildCheckoutSection(authProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBranchSelector(AuthProvider authProvider, List<Branch> branches, bool showBranchSelector) {
    return Column(
      children: [
        if (showBranchSelector)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.store, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select a branch to start selling',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _selectBranchForSale(),
                  icon: const Icon(Icons.arrow_drop_down),
                  label: const Text('Select Branch'),
                ),
              ],
            ),
          ),
        if (authProvider.user?.role == UserRole.ceo && 
            _selectedBranchId != null && 
            branches.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.store, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Branch: ${branches.firstWhere((b) => b.id == _selectedBranchId).name}',
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedBranchId = null;
                    });
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBarcodeScanner(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary,
      child: TextField(
        controller: _barcodeController,
        decoration: InputDecoration(
          hintText: 'Scan or enter barcode',
          fillColor: Colors.white,
          filled: true,
          prefixIcon: const Icon(Icons.qr_code_scanner),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (_barcodeController.text.isNotEmpty) {
                _scanProduct(_barcodeController.text.trim());
              }
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (value) {
          if (value.isNotEmpty && (authProvider.user?.role != UserRole.ceo || _selectedBranchId != null)) {
            _scanProduct(value.trim());
          } else if (value.isNotEmpty && authProvider.user?.role == UserRole.ceo && _selectedBranchId == null) {
            UiHelper.showInfo(context, 'Please select a branch first');
          }
        },
        autofocus: true,
        enabled: authProvider.user?.role != UserRole.ceo || _selectedBranchId != null,
      ),
    );
  }

  Widget _buildCart(AuthProvider authProvider) {
    if (_cart.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                (authProvider.user?.role == UserRole.ceo && _selectedBranchId == null)
                    ? 'Select a branch to start selling'
                    : 'No items in cart',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (authProvider.user?.role != UserRole.ceo || _selectedBranchId != null)
                Text(
                  'Scan or enter barcode to add products',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              child: Text(
                item.quantity.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(item.name),
            subtitle: Text(
                '${CurrencyFormatter.format(item.price)} x ${item.quantity} = ${CurrencyFormatter.format(item.subtotal)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (item.quantity > 1) {
                        final newIndex = _cart.indexWhere(
                          (i) => i.productId == item.productId,
                        );
                        _cart[newIndex] = SaleItem(
                          productId: item.productId,
                          productCode: item.productCode,
                          name: item.name,
                          price: item.price,
                          quantity: item.quantity - 1,
                          subtotal: item.price * (item.quantity - 1),
                          stock: item.stock,
                        );
                      } else {
                        _cart.removeAt(index);
                      }
                      _calculateTotal();
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item.quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (item.quantity < item.stock) {
                        final newIndex = _cart.indexWhere(
                          (i) => i.productId == item.productId,
                        );
                        _cart[newIndex] = SaleItem(
                          productId: item.productId,
                          productCode: item.productCode,
                          name: item.name,
                          price: item.price,
                          quantity: item.quantity + 1,
                          subtotal: item.price * (item.quantity + 1),
                          stock: item.stock,
                        );
                        _calculateTotal();
                      } else {
                        UiHelper.showError(context, 'Cannot exceed stock (${item.stock} available)');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                CurrencyFormatter.format(_total),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cart.isEmpty 
                  ? null 
                  : (_selectedBranchId == null && authProvider.user?.role == UserRole.ceo)
                      ? _selectBranchForSale
                      : _finalizeSale,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_selectedBranchId == null && authProvider.user?.role == UserRole.ceo
                  ? 'Select Branch & Complete Sale'
                  : 'Complete Sale'),
            ),
          ),
        ],
      ),
    );
  }


}




