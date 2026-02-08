import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  Future<void>? _authFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future only once
    _authFuture = _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    
    // Run auth check and minimum delay in parallel
    await Future.wait([
      authProvider.loadStoredAuth(),
      Future.delayed(const Duration(seconds: 2)), // Minimum splash time
    ]);
    
    // Try to extract user info from JWT token or get from API
    // For now, we'll check if token exists
    if (authProvider.isAuthenticated) {
      // Try to get user role from stored preferences
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString('user_role');
      final username = prefs.getString('user_username');
      
      if (roleString != null && username != null) {
        // Create a minimal user object
        authProvider.setUser(User(
          userId: '',
          username: username,
          firstName: '',
          lastName: '',
          email: '',
          role: UserRole.fromString(roleString),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // primaryNavy
                    Color(0xFF1E293B), // slatePrimary
                    Color(0xFF334155),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05), // Subtle background for logo
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Loading Indicator
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        // Use Consumer to react to auth state changes AFTER initialization
        return Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isAuthenticated
                ? const DashboardScreen()
                : const LoginScreen();
          },
        );
      },
    );
  }
}
