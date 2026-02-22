import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/business_provider.dart';
import 'providers/sync_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/business_service.dart';
import 'services/product_service.dart';
import 'services/sales_service.dart';
import 'services/debt_service.dart';
import 'services/sync_service.dart';
import 'services/analytics_service.dart';
import 'services/database_helper.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initializeForPlatform();
  runApp(const FlipApp());
}

class FlipApp extends StatelessWidget {
  const FlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final authService = AuthService();
    final apiService = ApiService();
    final businessService = BusinessService(apiService);
    final productService = ProductService(apiService);
    final salesService = SalesService(apiService);
    final debtService = DebtService(apiService);
    final analyticsService = AnalyticsService(apiService);
    final syncService = SyncService(apiService, salesService, debtService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BusinessProvider(businessService, productService, debtService, analyticsService, apiService, salesService),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(syncService),
        ),
      ],
      child: Consumer2<AuthProvider, ConnectivityProvider>(
        builder: (context, authProvider, connectivityProvider, _) {
          return MaterialApp(
            title: 'Flip POS System',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const AuthGuard(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
