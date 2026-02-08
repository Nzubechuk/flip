import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/jwt_decoder.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  User? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;

  AuthProvider(this._authService, this._apiService);

  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;

  Future<void> loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final refresh = prefs.getString('refresh_token');
    final userJson = prefs.getString('user');

      if (token != null) {
        _accessToken = token;
        _apiService.setAccessToken(token);
        
        // Try to extract role from JWT
        try {
          final roleString = JwtDecoder.extractRole(token);
          final usernameFromToken = JwtDecoder.extractUsername(token);
          final storedUsername = prefs.getString('user_username');
          
          if (roleString != null) {
            _user = User(
              userId: '',
              username: usernameFromToken ?? storedUsername ?? '',
              firstName: '',
              lastName: '',
              email: '',
              role: UserRole.fromString(roleString),
              branchId: JwtDecoder.extractBranchId(token),
              businessId: JwtDecoder.extractBusinessId(token),
            );
          }
        } catch (e) {
          // If we can't decode, continue without user
        }
        
        if (refresh != null) {
          _refreshToken = refresh;
        }
        notifyListeners();
      }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);
      
      // Check if response contains tokens
      if (response == null || 
          (!response.containsKey('accessToken') && !response.containsKey('token'))) {
        throw Exception('Invalid response from server: Missing authentication token');
      }
      
      _accessToken = response['accessToken'] ?? response['token'];
      _refreshToken = response['refreshToken'];

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Login failed: No access token received');
      }

      _apiService.setAccessToken(_accessToken!);

      // Store tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      await prefs.setString('user_username', username);

      // Extract role from JWT token
      try {
        final roleString = JwtDecoder.extractRole(_accessToken!);
        final usernameFromToken = JwtDecoder.extractUsername(_accessToken!) ?? username;
        
        if (roleString != null) {
          await prefs.setString('user_role', roleString);
          
          // Create user object with claims from JWT
          _user = User(
            userId: response['userId'] ?? '',
            username: usernameFromToken,
            firstName: response['firstName'] ?? '',
            lastName: response['lastName'] ?? '',
            email: response['email'] ?? '',
            role: UserRole.fromString(roleString),
            branchId: JwtDecoder.extractBranchId(_accessToken!),
            businessId: JwtDecoder.extractBusinessId(_accessToken!),
          );
        } else {
          // If role can't be extracted, try to get from response
          if (response.containsKey('role')) {
            final roleFromResponse = response['role'];
            await prefs.setString('user_role', roleFromResponse.toString());
            _user = User(
              userId: '',
              username: usernameFromToken,
              firstName: '',
              lastName: '',
              email: '',
              role: UserRole.fromString(roleFromResponse.toString()),
            );
          }
        }
      } catch (e) {
        // If we can't decode, user will need to be set later
        // But don't fail the login if we have a valid token
      }
    } catch (e) {
      // Clear any partial state
      _accessToken = null;
      _refreshToken = null;
      _user = null;
      _apiService.setAccessToken('');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    // Store user info
    await prefs.setString('user_role', user.role.name);
    await prefs.setString('user_username', user.username);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _apiService.setAccessToken('');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    await prefs.remove('user_role');
    await prefs.remove('user_username');

    notifyListeners();
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _authService.refreshToken(_refreshToken!);
      _accessToken = response['accessToken'];
      if (_accessToken != null) {
        _apiService.setAccessToken(_accessToken!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
      }
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> registerBusiness({
    required String businessName,
    String? businessRegNumber,
    required String ceoUsername,
    required String ceoPassword,
    required String ceoFirstName,
    required String ceoLastName,
    required String ceoEmail,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.registerBusiness(
        businessName: businessName,
        businessRegNumber: businessRegNumber,
        ceoUsername: ceoUsername,
        ceoPassword: ceoPassword,
        ceoFirstName: ceoFirstName,
        ceoLastName: ceoLastName,
        ceoEmail: ceoEmail,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

