import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/api_service.dart';
import '../../../models/business.dart';
import '../branches/add_branch_screen.dart';
import '../products/add_product_screen.dart';
import '../branches/branches_screen.dart';
import '../users/ceo_users_screen.dart';
import '../products/ceo_products_screen.dart';
import '../products/record_receipt_screen.dart';
import '../products/receipts_list_screen.dart';
import '../debts/debts_screen.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/currency_formatter.dart';

class CeoHomeScreen extends StatefulWidget {
  final String businessId;

  const CeoHomeScreen({super.key, required this.businessId});

  @override
  State<CeoHomeScreen> createState() => _CeoHomeScreenState();
}

class _CeoHomeScreenState extends State<CeoHomeScreen> {
  Business? _business;
  int _branchesCount = 0;
  int _managersCount = 0;
  int _clerksCount = 0;
  int _productsCount = 0;
  double _totalRevenue = 0.0;
  double _totalDebts = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final businessProvider = context.read<BusinessProvider>();
      
      // Load business data
      await businessProvider.loadBusinessData(widget.businessId);
      
      setState(() {
        _business = businessProvider.business;
        _branchesCount = businessProvider.branches.length;
        _managersCount = businessProvider.managers.length;
        _clerksCount = businessProvider.clerks.length;
        _productsCount = businessProvider.allProducts.length;
        _totalDebts = businessProvider.totalDebtsAmount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D6B6B), // Deep Teal
                      const Color(0xFF129494), // Lighter Teal
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _business?.name ?? 'Business',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
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
            const SizedBox(height: 24),
            
            // Statistics Grid
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResponsiveHelper.isMobile(context) ? 2 : ResponsiveHelper.getGridCrossAxisCount(context);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: (constraints.maxWidth / crossAxisCount - 24) / 180,
                  children: [
                _buildStatCard(
                  context,
                  'Branches',
                  _branchesCount.toString(),
                  Icons.store_outlined,
                  const Color(0xFF3B82F6), // accentBlue
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BranchesScreen(businessId: widget.businessId),
                      ),
                    );
                  },
                ),
                _buildStatCard(
                  context,
                  'Active staff',
                  (_managersCount + _clerksCount).toString(),
                  Icons.people_alt_outlined,
                  const Color(0xFF10B981), // emeraldGreen
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CeoUsersScreen(businessId: widget.businessId),
                      ),
                    );
                  },
                ),
                 _buildStatCard(
                  context,
                  'Products',
                  _productsCount.toString(),
                  Icons.inventory_2_outlined,
                  const Color(0xFF8B5CF6), // purple
                  null,
                ),
                _buildStatCard(
                  context,
                  'Total Debts',
                  CurrencyFormatter.format(_totalDebts),
                  Icons.money_off_outlined,
                  const Color(0xFFEF4444), // red
                  null,
                ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResponsiveHelper.isMobile(context) ? 2 : 4;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
                      child: _buildActionCard(
                        context,
                        'Add Branch',
                        Icons.add_business_outlined,
                        const Color(0xFF3B82F6), // accentBlue
                        () => _navigateToAddBranch(context),
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
                      child: _buildActionCard(
                        context,
                        'Add Product',
                        Icons.add_shopping_cart_outlined,
                        const Color(0xFF10B981), // emeraldGreen
                        () => _navigateToAddProduct(context),
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
                      child: _buildActionCard(
                        context,
                        'Record Receipt',
                        Icons.receipt_long,
                        Colors.orange, 
                        () => _navigateToRecordReceipt(context),
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
                      child: _buildActionCard(
                        context,
                        'View Receipts',
                        Icons.history_edu,
                        const Color(0xFF10B981), // Emerald
                        () => _navigateToReceiptsList(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32), // Extra padding at bottom to prevent overflow
          ],
        ),
      ),
    );
  }

  void _navigateToAddBranch(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddBranchScreen(),
      ),
    );
    if (result == true && mounted) {
      _loadDashboardData();
    }
  }

  void _navigateToAddProduct(BuildContext context) async {
    final businessProvider = context.read<BusinessProvider>();
    final businessId = widget.businessId;
    
    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business ID not available')),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
    if (result == true && mounted) {
      _loadDashboardData();
    }
  }

  void _navigateToRecordReceipt(BuildContext context) async {
    final businessProvider = context.read<BusinessProvider>();
    final businessId = widget.businessId;
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordReceiptScreen(businessId: businessId),
      ),
    );
    if (result == true && mounted) {
      _loadDashboardData();
    }
  }

  void _navigateToReceiptsList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptsListScreen(businessId: widget.businessId),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.04), // Slightly more visible
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16), // Increased padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color), // Larger icon
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith( // Slightly smaller to avoid overflow
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.03),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B), // slatePrimary
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

