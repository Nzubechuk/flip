import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/analytics_service.dart';
import '../../../services/api_service.dart';
import '../../../models/business.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/responsive_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  final String? businessId;

  const AnalyticsScreen({super.key, this.businessId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with RouteAware {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _lowStockThreshold = 10;
  String? _selectedBranchId;

  double _totalRevenue = 0.0;
  int _totalTransactions = 0;
  List<Map<String, dynamic>> _bestSellingProducts = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _mostStockedProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh when screen becomes visible
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }
      final analyticsService = AnalyticsService(apiService);

      // Load all analytics data in parallel
      final results = await Future.wait([
        analyticsService.getTotalRevenue(_startDate, _endDate, branchId: _selectedBranchId),
        analyticsService.getTransactions(_startDate, _endDate, branchId: _selectedBranchId),
        analyticsService.getBestSellingProducts(_startDate, _endDate, branchId: _selectedBranchId),
        analyticsService.getLowStockProducts(_lowStockThreshold, branchId: _selectedBranchId),
        analyticsService.getMostStockedProducts(branchId: _selectedBranchId),
      ]);

      if (mounted) {
        setState(() {
          _totalRevenue = results[0] as double;
          final transactions = results[1] as List<Map<String, dynamic>>;
          _totalTransactions = transactions.isNotEmpty 
              ? (transactions.last['total_products'] ?? transactions.length) 
              : 0;
          _bestSellingProducts = results[2] as List<Map<String, dynamic>>;
          _lowStockProducts = results[3] as List<Map<String, dynamic>>;
          _mostStockedProducts = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Date Range and Branch Selector
              Text(
                'Analytics Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    ),
                  ),
                  Consumer<BusinessProvider>(
                    builder: (context, provider, child) {
                      final branches = provider.branches;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedBranchId,
                            hint: const Text('All Branches'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Branches'),
                              ),
                              ...branches.map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedBranchId = value;
                              });
                              _loadAnalytics();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadAnalytics,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Revenue and Transactions Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Revenue',
                            CurrencyFormatter.format(_totalRevenue),
                            Icons.account_balance_wallet_outlined,
                            const Color(0xFF10B981), // Emerald
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Transactions',
                            _totalTransactions.toString(),
                            Icons.receipt_long_outlined,
                            const Color(0xFF3B82F6), // Blue
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (isMobile)
                      Column(
                        children: [
                          _buildBestSellingSection(),
                          const SizedBox(height: 24),
                          _buildLowStockSection(),
                          const SizedBox(height: 24),
                          _buildMostStockedSection(),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildBestSellingSection(),
                                const SizedBox(height: 24),
                                _buildMostStockedSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildLowStockSection(),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestSellingSection() {
    return _buildSectionCard(
      context,
      'Best Selling Products',
      Icons.trending_up,
      _bestSellingProducts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No sales data available'),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bestSellingProducts.length > 10
                  ? 10
                  : _bestSellingProducts.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final product = _bestSellingProducts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  title: Text(product['product'] ?? 'Unknown'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Qty: ${product['quantity'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product['revenue'] != null)
                        Text(
                          CurrencyFormatter.format(product['revenue'] as double),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLowStockSection() {
    return _buildSectionCard(
      context,
      'Low Stock Alert',
      Icons.warning,
      _lowStockProducts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No low stock items'),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('Threshold: '),
                      DropdownButton<int>(
                        value: _lowStockThreshold,
                        items: [5, 10, 15, 20, 25, 50]
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _lowStockThreshold = value;
                            });
                            _loadAnalytics();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lowStockProducts.length > 10
                      ? 10
                      : _lowStockProducts.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = _lowStockProducts[index];
                    final stock = product['stock'] ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      title: Text(product['product'] ?? 'Unknown'),
                      subtitle: Text(
                        product['branch'] ?? 'Unknown Branch',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: stock < 5
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: $stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: stock < 5
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildMostStockedSection() {
    return _buildSectionCard(
      context,
      'Most Stocked Products',
      Icons.inventory,
      _mostStockedProducts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No products available'),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mostStockedProducts.length > 10
                  ? 10
                  : _mostStockedProducts.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final product = _mostStockedProducts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(product['product'] ?? 'Unknown'),
                  subtitle: Text(
                    product['branch'] ?? 'Unknown Branch',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stock: ${product['stock'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }



  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B), // slateSecondary
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF1E293B), // slatePrimary
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }
}
