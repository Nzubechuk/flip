import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/sync_provider.dart';
import '../../utils/toast_helper.dart';
import '../../models/user.dart';
import 'ceo/ceo_dashboard.dart';
import 'manager/manager_dashboard.dart';
import 'clerk/clerk_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for connectivity changes to trigger sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivity = context.read<ConnectivityProvider>();
      connectivity.addListener(_handleConnectivityChange);
    });
  }

  @override
  void dispose() {
    // Note: We need to be careful with context in dispose, but since we're using context.read in initState 
    // we should really use a reference or handle it differently.
    // For simplicity here, we'll assume the provider outlives the screen.
    super.dispose();
  }

  void _handleConnectivityChange() {
    final connectivity = context.read<ConnectivityProvider>();
    if (connectivity.isOnline) {
      debugPrint('Device is online, triggering sync...');
      final authProvider = context.read<AuthProvider>();
      final syncProvider = context.read<SyncProvider>();
      
      syncProvider.sync(authProvider.user?.businessId).then((_) {
        if (mounted) {
          ToastHelper.showSuccess(context, 'Synchronization complete. All data is up to date.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _getUserRole(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? UserRole.clerk;

        Widget dashboard;
        switch (role) {
          case UserRole.ceo:
            dashboard = const CeoDashboard();
            break;
          case UserRole.manager:
            dashboard = const ManagerDashboard();
            break;
          case UserRole.clerk:
            dashboard = const ClerkDashboard();
            break;
        }

        return Stack(
          children: [
            dashboard,
            Consumer<SyncProvider>(
              builder: (context, syncProvider, _) {
                if (syncProvider.isSyncing) {
                  return Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Syncing data...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  Future<UserRole?> _getUserRole(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      return authProvider.user!.role;
    }

    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('user_role');
    if (roleString != null) {
      return UserRole.fromString(roleString);
    }

    return UserRole.clerk;
  }
}

