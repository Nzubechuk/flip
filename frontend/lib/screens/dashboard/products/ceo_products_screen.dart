import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/product_service.dart';
import '../../../services/api_service.dart';
import '../../../models/product.dart';
import '../../../models/business.dart';
import '../../../utils/currency_formatter.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../utils/responsive_helper.dart';

class CeoProductsScreen extends StatefulWidget {
  final String? businessId;

  const CeoProductsScreen({super.key, this.businessId});

  @override
  State<CeoProductsScreen> createState() => _CeoProductsScreenState();
}

class _CeoProductsScreenState extends State<CeoProductsScreen> {
  String? _selectedBranchId;
  String? _selectedBranchName;

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    
    // Get businessId from provider if not provided
    final businessId = widget.businessId ?? businessProvider.businessId;
    
    // Load data if we have businessId and data is empty
    if (businessId != null && businessProvider.branches.isEmpty && !businessProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        businessProvider.loadBusinessData(businessId);
      });
    }
    
    final branches = businessProvider.branches;
    final allProducts = businessProvider.allProducts;

    // Filter products by selected branch
    final products = _selectedBranchId == null
        ? allProducts
        : _selectedBranchId == 'global'
            ? allProducts.where((p) => p.branchId == null || p.branchId.isEmpty).toList()
            : allProducts.where((p) => p.branchId == _selectedBranchId).toList();

    return Scaffold(
      body: Column(
        children: [
          // Branch Filter
          if (branches.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Filter by Branch:',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedBranchId,
                      isExpanded: true,
                      hint: const Text('All Products'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Products'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'global',
                          child: Text('Global/Business Level'),
                        ),
                        ...branches.map((branch) => DropdownMenuItem<String>(
                              value: branch.id,
                              child: Text(branch.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBranchId = value;
                          if (value == null) {
                            _selectedBranchName = 'All Branches';
                          } else if (value == 'global') {
                            _selectedBranchName = 'Global';
                          } else {
                            _selectedBranchName = branches.firstWhere((b) => b.id == value).name;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Products List
          Expanded(
            child: businessProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _selectedBranchId == null
                                  ? 'No products yet'
                                  : 'No products in ${_selectedBranchName ?? "this branch"}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                          onRefresh: () => businessProvider.refresh(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0), // Smaller top padding since filters are above
                                child: Text(
                                  'Manage Products',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
                                    if (crossAxisCount > 1) {
                                      return GridView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 1.3,
                                        ),
                                        itemCount: products.length,
                                        itemBuilder: (context, index) => _buildProductCard(products[index]),
                                      );
                                    }
                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) => _buildProductCard(products[index]),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Wrap(
          direction: Axis.vertical,
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
          FloatingActionButton(
            heroTag: 'barcode',
            onPressed: () async {
              if (branches.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please create a branch first'),
                  ),
                );
                return;
              }
              // TODO: Navigate to barcode scan with branch selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barcode scan coming soon')),
              );
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () async {
              if (branches.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please create a branch first'),
                  ),
                );
                return;
              }
              
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(
                    branchId: _selectedBranchId,
                  ),
                ),
              );
              
              if (result == true && mounted) {
                businessProvider.refresh();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProductCard(Product product) {
    final color = product.stock < 10 ? Colors.orange : Theme.of(context).colorScheme.primary;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToEdit(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.03),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_outlined, size: 24, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B), // slatePrimary
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.productCode ?? 'No SKU',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: const [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEdit(product);
                      } else if (value == 'delete') {
                        _showDeleteDialog(product);
                      }
                    },
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.store_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      product.branchName ?? 'No Branch',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (product.stock < 10 ? Colors.orange : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.stock < 10 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                          size: 14,
                          color: product.stock < 10 ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            color: product.stock < 10 ? Colors.orange : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(Product product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
    if (result == true && mounted) {
      final businessProvider = context.read<BusinessProvider>();
      await businessProvider.refreshAllProducts();
    }
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final productService = ProductService(apiService);

      await productService.deleteProduct(product.id);
      
      if (mounted) {
        final businessProvider = context.read<BusinessProvider>();
        businessProvider.removeProduct(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: ${e.toString()}')),
        );
      }
    }
  }
}

