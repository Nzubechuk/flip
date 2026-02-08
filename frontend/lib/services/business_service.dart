import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/user.dart';
import 'api_service.dart';

class BusinessService {
  final ApiService _apiService;

  BusinessService(this._apiService);

  Future<List<Branch>> getBranches(String businessId) async {
    final response = await _apiService.get('/api/business/$businessId/branches');
    if (response is List) {
      return response.map((json) => Branch.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Branch> createBranch(
    String businessId,
    String name,
    String? location,
    String? managerId,
  ) async {
    final body = {
      'name': name,
      'location': location,
    };
    if (managerId != null) {
      body['managerId'] = managerId;
    }

    final response =
        await _apiService.post('/api/business/$businessId/create-branch', body);
    return Branch.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateBranch(
    String businessId,
    String branchId,
    String name,
    String? location,
  ) async {
    await _apiService.put(
      '/api/business/$businessId/branch/$branchId/update',
      {'name': name, 'location': location},
    );
  }

  Future<void> deleteBranch(String businessId, String branchId) async {
    await _apiService.delete('/api/business/$businessId/branch/$branchId/delete');
  }

  Future<User> registerManager(
    String businessId,
    String username,
    String password,
    String firstName,
    String lastName,
    String email,
    String? branchId,
  ) async {
    final body = {
      'username': username,
      'password': password,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
    };
    if (branchId != null) {
      body['branchId'] = branchId;
    }

    final response =
        await _apiService.post('/api/business/$businessId/register-manager', body);
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<User> registerClerk(
    String businessId,
    String username,
    String password,
    String firstName,
    String lastName,
    String email,
    String? branchId,
  ) async {
    final body = {
      'username': username,
      'password': password,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
    };
    if (branchId != null) {
      body['branchId'] = branchId;
    }

    final response =
        await _apiService.post('/api/business/$businessId/register-clerk', body);
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<List<User>> getManagers(String businessId) async {
    final response = await _apiService.get('/api/business/$businessId/managers');
    if (response is List) {
      return response.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<User>> getClerks(String businessId) async {
    final response = await _apiService.get('/api/business/$businessId/clerks');
    if (response is List) {
      return response.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> deleteManager(String businessId, String managerId) async {
    await _apiService.delete('/api/business/$businessId/manager/$managerId/delete');
  }

  Future<void> updateManager(
    String businessId,
    String managerId,
    String username,
    String? password,
    String? firstName,
    String? lastName,
    String? email,
  ) async {
    final body = <String, dynamic>{
      'username': username,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    if (firstName != null && firstName.isNotEmpty) {
      body['firstname'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      body['lastname'] = lastName;
    }
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    await _apiService.put('/api/business/$businessId/manager/$managerId/update', body);
  }

  Future<void> updateClerk(
    String businessId,
    String clerkId,
    String username,
    String? password,
    String? firstName,
    String? lastName,
    String? email,
  ) async {
    final body = <String, dynamic>{
      'username': username,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    if (firstName != null && firstName.isNotEmpty) {
      body['firstname'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      body['lastname'] = lastName;
    }
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    await _apiService.put('/api/business/$businessId/clerk/$clerkId/update', body);
  }

  Future<void> deleteClerk(String businessId, String clerkId) async {
    await _apiService.delete('/api/business/$businessId/clerk/$clerkId/delete');
  }

  Future<Business> getCurrentBusiness() async {
    try {
      final response = await _apiService.get('/api/business/my-business');
      
      if (response is! Map) {
        throw Exception('Invalid response format from server. Expected a map but got: ${response.runtimeType}');
      }
      
      // Cast to Map<String, dynamic> for type safety
      final responseMap = response as Map<String, dynamic>;
      
      // Debug: Log the response keys
      debugPrint('Business API Response keys: ${responseMap.keys.toList()}');
      debugPrint('Business API Response: $responseMap');
      
      final business = Business.fromJson(responseMap);
      
      if (business.id.isEmpty) {
        throw Exception(
          'Business ID is missing in the response. '
          'This usually means your account is not associated with a business. '
          'Please ensure you registered a business account, or contact support.'
        );
      }
      
      return business;
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get business: ${e.toString()}');
    }
  }
}




