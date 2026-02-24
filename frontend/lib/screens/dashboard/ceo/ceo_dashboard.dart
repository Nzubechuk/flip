import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/api_service.dart';
import 'ceo_home_screen.dart';
import '../branches/branches_screen.dart';
import '../users/ceo_users_screen.dart';
import '../products/ceo_products_screen.dart';
import '../analytics/analytics_screen.dart';
import '../pos/pos_screen.dart';
import '../debts/debts_screen.dart';
import '../../../utils/ui_helper.dart';
import '../../../utils/responsive_helper.dart';

class CeoDashboard extends StatefulWidget {
  const CeoDashboard({super.key});

  @override
  State<CeoDashboard> createState() => _CeoDashboardState();
}

class _CeoDashboardState extends State<CeoDashboard> {
  int _currentIndex = 0;
  String? _businessId;
  bool _isInitializing = true;
  bool _isLoggingOut = false;
  List<Widget>? _cachedScreens;

  @override
  void initState() {
    super.initState();
    _initializeBusiness();
  }

  Future<void> _initializeBusiness() async {
    try {
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      
      // Check if business is already loaded in provider
      if (businessProvider.business != null && businessProvider.businessId != null) {
        if (mounted) {
          setState(() {
            _businessId = businessProvider.businessId;
            _isInitializing = false;
          });
        }
        return;
      }
      
      if (authProvider.accessToken == null) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not authenticated. Please login again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Get current CEO's business
      final apiService = ApiService()..setAccessToken(authProvider.accessToken!);
      final businessService = BusinessService(apiService);
      final business = await businessService.getCurrentBusiness();
      
      if (!mounted) return;
      
      // Validate business ID
      if (business.id.isEmpty) {
        throw Exception('Business ID is empty. The user may not be associated with a business. Please contact support or register a business.');
      }
      
      // Initialize business provider
      businessProvider.setBusiness(business);
      
      // Load all business data
      await businessProvider.loadBusinessData(business.id);
      
      if (!mounted) return;
      
      setState(() {
        _businessId = business.id;
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        // Try to get businessId from provider as fallback
        final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
        final fallbackBusinessId = businessProvider.businessId;
        
        setState(() {
          _businessId = fallbackBusinessId; // Use fallback if available
          _isInitializing = false;
        });
        
        // Always log the error for debugging
        debugPrint('Error initializing business: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        
        // Only show error if we don't have a fallback
        if (fallbackBusinessId == null || fallbackBusinessId.isEmpty) {
          // Show detailed error
          String errorMessage = e.toString().replaceAll('Exception: ', '');
          
          // Clean up common error prefixes
          if (errorMessage.startsWith('Error ')) {
            errorMessage = errorMessage.replaceFirst('Error ', '');
          }
          
          // Show error dialog with retry option
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(child: Text('Business Loading Error')),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unable to load your business information. Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            errorMessage,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Possible causes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Your account is not linked to a business'),
                        const Text('• Network connection issue'),
                        const Text('• Backend server is not running'),
                        const Text('• Authentication token expired'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isInitializing = true;
                          _businessId = null;
                        });
                        _initializeBusiness();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
          });
        }
      }
    }
  }

  List<Widget> _buildScreens(String? businessId) {
    return [
      businessId != null && businessId.isNotEmpty
          ? CeoHomeScreen(businessId: businessId)
          : _buildErrorScreen(),
      CeoProductsScreen(businessId: businessId),
      AnalyticsScreen(businessId: businessId),
      const PosScreen(),
      DebtsScreen(businessId: businessId),
    ];
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Business Not Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your business information.\n\nThis may happen if:\n• Your account is not linked to a business\n• There was a connection error\n• The business data needs to be refreshed',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                  _businessId = null;
                });
                _initializeBusiness();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Loading'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '';
      case 1:
        return 'Products';
      case 2:
        return 'Analytics';
      case 3:
        return 'POS';
      case 4:
        return 'Debts';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Cache screens — only recreate if businessId changes
    if (_cachedScreens == null || _cachedScreens!.isEmpty) {
      _cachedScreens = _buildScreens(_businessId);
    }
    final screens = _cachedScreens!;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        elevation: 0,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error logging out: $e')),
                          );
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
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('Sales'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.money_off_outlined),
                  selectedIcon: Icon(Icons.money_off),
                  label: Text('Debts'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
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
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: 'Sales',
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
}
