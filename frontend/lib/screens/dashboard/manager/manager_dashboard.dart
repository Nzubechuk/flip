import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/product_service.dart';
import '../../../services/analytics_service.dart';
import '../../../models/user.dart';
import '../products/products_screen.dart';
import '../analytics/analytics_screen.dart';
import '../debts/debts_screen.dart';
import '../pos/pos_screen.dart';
import '../../../utils/ui_helper.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/toast_helper.dart';
import '../../../utils/responsive_helper.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;
  bool _isLoggingOut = false;

  List<Widget> _buildScreens() {
    return [
      const ManagerHomeScreen(),
      const PosScreen(),
      const ProductsScreen(),
      Consumer<AuthProvider>(
        builder: (context, auth, _) => AnalyticsScreen(
          businessId: auth.user?.businessId,
          branchId: auth.user?.branchId,
        ),
      ),
      const DebtsScreen(),
    ];
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _isLoggingOut
                ? null
                : () async {
                    final shouldLogout = await UiHelper.showLogoutConfirmation(context);

                    if (shouldLogout == true && mounted) {
                      setState(() {
                        _isLoggingOut = true;
                      });

                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();

                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isLoggingOut = false;
                          });
                          UiHelper.showError(context, 'Error logging out: $e');
                        }
                      }
                    }
                  },
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  selectedIcon: Icon(Icons.shopping_cart),
                  label: Text('Sales'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Products'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.money_off_outlined),
                  selectedIcon: Icon(Icons.money_off),
                  label: Text('Debts'),
                ),
              ],
            ),
          Expanded(child: _buildScreens()[_currentIndex]),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  selectedIcon: Icon(Icons.shopping_cart),
                  label: 'Sales',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.money_off_outlined),
                  selectedIcon: Icon(Icons.money_off),
                  label: 'Debts',
                ),
              ],
            )
          : null,
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '';
      case 1:
        return 'Branch Sales (POS)';
      case 2:
        return 'Product Inventory';
      case 3:
        return 'Business Analytics';
      case 4:
        return 'Consumer Debts';
      default:
        return '';
    }
  }
}

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _productCount = 0;
  int _lowStockCount = 0;
  double _todaySales = 0.0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final branchId = authProvider.user?.branchId;

      if (branchId == null) {
        throw Exception('No branch assigned to this manager');
      }

      final apiService = ApiService();
      if (authProvider.accessToken != null) {
        apiService.setAccessToken(authProvider.accessToken!);
      }

      final productService = ProductService(apiService);
      final analyticsService = AnalyticsService(apiService);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      
      // Epoch for "ever"
      final epoch = DateTime(2020, 1, 1);

      final results = await Future.wait([
        productService.getProducts(branchId),
        analyticsService.getLowStockProducts(10, branchId: branchId),
        analyticsService.getTotalRevenue(todayStart, todayEnd, branchId: branchId),
        analyticsService.getTotalRevenue(epoch, now, branchId: branchId),
      ]);

      if (mounted) {
        setState(() {
          _productCount = (results[0] as List).length;
          _lowStockCount = (results[1] as List).length;
          _todaySales = results[2] as double;
          _totalRevenue = results[3] as double;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading manager stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(context, 'Failed to load stats: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D6B6B), // Deep Teal
                      Color(0xFF129494), // Lighter Teal
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
                                'Welcome, Manager',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage products and view analytics for your branch',
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
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ))
            else
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
                      _buildStatCard(context, 'Products', '$_productCount', Icons.inventory_2_outlined, const Color(0xFF3B82F6)), // Blue
                      _buildStatCard(context, 'Low Stock', '$_lowStockCount', Icons.report_problem_outlined, const Color(0xFFF59E0B)), // Orange/Amber
                      _buildStatCard(context, 'Today Sales', CurrencyFormatter.format(_todaySales), Icons.payments_outlined, const Color(0xFF10B981)), // Green/Emerald
                      _buildStatCard(context, 'Total Revenue', CurrencyFormatter.format(_totalRevenue), Icons.trending_up, const Color(0xFF8B5CF6)), // Purple
                    ],
                  );
                },
              ),
          ],
        ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith( // Slightly smaller to avoid overflow
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
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
    );
  }
}




