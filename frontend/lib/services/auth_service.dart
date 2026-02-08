import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UnverifiedUserException implements Exception {
  final String email;
  UnverifiedUserException(this.email);
  @override
  String toString() => 'UnverifiedUserException: $email';
}

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  static const Duration timeout = Duration(seconds: 30);

  /// Test connectivity to the backend server
  Future<bool> testConnection() async {
    try {
      await http
          .get(Uri.parse('$baseUrl/api/auth/login'))
          .timeout(const Duration(seconds: 5));
      // Any response (even 405 Method Not Allowed) means server is reachable
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.authLogin}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        // Check if unverified
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && 
              errorBody['message'] == 'User is not verified' && 
              errorBody.containsKey('email')) {
             throw UnverifiedUserException(errorBody['email']);
          }
        } catch (e) {
          if (e is UnverifiedUserException) rethrow;
        }
        throw Exception('Access denied');
      } else {
        // Try to parse error message from response
        String errorMessage = 'Login failed';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          } else {
            errorMessage = response.body.isNotEmpty 
                ? response.body 
                : 'Login failed with status ${response.statusCode}';
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'Login failed with status ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Connection timeout');
    } on http.ClientException {
      throw Exception('Connection error');
    } catch (e) {
      if (e is UnverifiedUserException || e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.authRefresh}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refreshToken': refreshToken,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Token refresh failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Token refresh failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> registerBusiness({
    required String businessName,
    String? businessRegNumber,
    required String ceoUsername,
    required String ceoPassword,
    required String ceoFirstName,
    required String ceoLastName,
    required String ceoEmail,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.businessRegister}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': businessName,
              'businessRegNumber': businessRegNumber,
              'ceo': {
                'username': ceoUsername,
                'password': ceoPassword,
                'firstname': ceoFirstName,
                'lastname': ceoLastName,
                'email': ceoEmail,
              },
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        String errorMessage = 'Registration failed';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          } else {
            errorMessage = response.body.isNotEmpty 
                ? response.body 
                : 'Registration failed with status ${response.statusCode}';
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'Registration failed with status ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Connection timeout');
    } on http.ClientException {
      throw Exception('Connection error');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Registration failed');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.authForgotPassword}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        String errorMessage = 'Failed to send reset email';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is! Exception) {
        throw Exception('An unexpected error occurred: $e');
      }
      rethrow;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.authResetPassword}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': token,
              'newPassword': newPassword,
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        String errorMessage = 'Failed to reset password';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is! Exception) {
        throw Exception('An unexpected error occurred: $e');
      }
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.authVerifyEmail}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        String errorMessage = 'Verification failed';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is! Exception) {
        throw Exception('An unexpected error occurred: $e');
      }
      rethrow;
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.authResendVerification}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to resend code');
      }
    } catch (e) {
      if (e is! Exception) {
        throw Exception('An unexpected error occurred: $e');
      }
      rethrow;
    }
  }
}




