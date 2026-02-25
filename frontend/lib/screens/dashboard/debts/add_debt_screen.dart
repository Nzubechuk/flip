import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/toast_helper.dart';
import '../../../services/api_service.dart';
import '../../../services/debt_service.dart';
import '../../../services/sales_service.dart';
import '../../../models/sale.dart';
import '../../../models/user.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../services/database_helper.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/ui_helper.dart';
import '../../../utils/currency_formatter.dart';

class AddDebtScreen extends StatefulWidget {
  final String? branchId;
  const AddDebtScreen({super.key, this.branchId});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final List<SaleItem> _cart = [];
  final _barcodeController = TextEditingController();
  final _consumerNameController = TextEditingController();
  double _total = 0.0;
  String? _selectedBranchId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.branchId;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _consumerNameController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    _total = _cart.fold(0.0, (sum, item) => sum + item.subtotal);
    setState(() {});
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _cart[index];
      final newQuantity = item.quantity + delta;
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = SaleItem(
          productId: item.productId,
          productCode: item.productCode,
          name: item.name,
          price: item.price,
          quantity: newQuantity,
          subtotal: item.price * newQuantity,
          stock: item.stock,
        );
      }
      _calculateTotal();
    });
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

      final productCode = product.productCode ?? product.upc ?? product.ean13 ?? product.id;
      
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
      // If network fails during call, try to queue locally
      await _queueDebtLocally();
    }
  }

  Future<void> _recordDebt() async {
    if (_consumerNameController.text.isEmpty) {
      UiHelper.showInfo(context, 'Please enter consumer name');
      return;
    }

    if (_cart.isEmpty) {
      UiHelper.showInfo(context, 'Cart is empty');
      return;
    }

    if (_selectedBranchId == null) {
      UiHelper.showInfo(context, 'Please select a branch');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final businessProvider = context.read<BusinessProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final debtService = DebtService(apiService);

      final items = _cart.map((item) => {
        'name': item.name,
        'productCode': item.productCode,
        'quantity': item.quantity,
      }).toList();

      final connectivity = context.read<ConnectivityProvider>();
      if (connectivity.isOffline) {
        await _queueDebtLocally();
        return;
      }

      await debtService.recordDebt(
        consumerName: _consumerNameController.text.trim(),
        items: items,
        branchId: _selectedBranchId!,
        businessId: businessProvider.businessId!,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ToastHelper.showSuccess(context, 'Debt recorded successfully');
    } catch (e) {
      debugPrint('Error recording debt: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debt Recording Failed'),
          content: SelectableText(ErrorHandler.formatException(e)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _queueDebtLocally() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.queueDebt(
        _consumerNameController.text.trim(),
        _cart,
        _selectedBranchId!,
      );
      
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
          content: const Text('Connection is unstable. The debt has been saved locally and will be synchronized automatically once your internet is stable.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    } catch (e) {
      UiHelper.showError(context, 'Failed to queue debt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final authProvider = context.watch<AuthProvider>();
    final branches = businessProvider.branches;

    return Scaffold(
      appBar: AppBar(title: const Text('Record New Debt')),
      body: SingleChildScrollView(
        child: Column(
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _consumerNameController,
                decoration: const InputDecoration(
                  labelText: 'Consumer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            if (authProvider.user?.role == UserRole.ceo && widget.branchId == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Select Branch',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                  items: branches.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.name),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedBranchId = val),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  hintText: 'Scan or enter barcode',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      if (_barcodeController.text.isNotEmpty) {
                        _scanProduct(_barcodeController.text.trim());
                      }
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (value) {
                  if (value.isNotEmpty) _scanProduct(value.trim());
                },
              ),
            ),
            if (_cart.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('No items added yet')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${CurrencyFormatter.format(item.price)} x ${item.quantity} = ${CurrencyFormatter.format(item.subtotal)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                          onPressed: () => _updateQuantity(index, -1),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                          onPressed: () => _updateQuantity(index, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _cart.removeAt(index);
                              _calculateTotal();
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Debt:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(_total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _recordDebt,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSaving ? const CircularProgressIndicator() : const Text('Record Debt'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
