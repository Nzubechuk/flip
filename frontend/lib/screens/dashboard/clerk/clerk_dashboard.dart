import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../pos/pos_screen.dart';
import '../debts/debts_screen.dart';
import '../../../utils/ui_helper.dart';
import '../../../utils/responsive_helper.dart';

class ClerkDashboard extends StatefulWidget {
  const ClerkDashboard({super.key});

  @override
  State<ClerkDashboard> createState() => _ClerkDashboardState();
}

class _ClerkDashboardState extends State<ClerkDashboard> {
  int _currentIndex = 0;
  bool _isLoggingOut = false;

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'POS';
      case 1:
        return 'Debts';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final branchId = user?.branchId;

    final List<Widget> _screens = [
      PosScreen(branchId: branchId),
      DebtsScreen(branchId: branchId),
    ];

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
              children: _screens,
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





