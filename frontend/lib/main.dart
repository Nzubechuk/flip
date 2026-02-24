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

  // Create services once at startup — not in build()
  final authService = AuthService();
  final apiService = ApiService();
  final businessService = BusinessService(apiService);
  final productService = ProductService(apiService);
  final salesService = SalesService(apiService);
  final debtService = DebtService(apiService);
  final analyticsService = AnalyticsService(apiService);
  final syncService = SyncService(apiService, salesService, debtService);

  runApp(FlipApp(
    authService: authService,
    apiService: apiService,
    businessService: businessService,
    productService: productService,
    salesService: salesService,
    debtService: debtService,
    analyticsService: analyticsService,
    syncService: syncService,
  ));
}

class FlipApp extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;
  final BusinessService businessService;
  final ProductService productService;
  final SalesService salesService;
  final DebtService debtService;
  final AnalyticsService analyticsService;
  final SyncService syncService;

  const FlipApp({
    super.key,
    required this.authService,
    required this.apiService,
    required this.businessService,
    required this.productService,
    required this.salesService,
    required this.debtService,
    required this.analyticsService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
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
      child: MaterialApp(
        title: 'Flip POS System',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGuard(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

