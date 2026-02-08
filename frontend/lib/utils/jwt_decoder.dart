import 'dart:convert';

/// Simple JWT decoder to extract claims from JWT token
/// For production use, consider using a proper JWT library like `jose` or `dart_jsonwebtoken`
class JwtDecoder {
  /// Decode JWT payload
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = base64Url.decode(normalizedPayload);
      final payloadJson = utf8.decode(decoded);
      return jsonDecode(payloadJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Extract role from JWT token
  /// The backend should include 'role' in the JWT claims
  static String? extractRole(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;

    // Try different possible claim names
    if (payload.containsKey('role')) {
      return payload['role'] as String?;
    }
    if (payload.containsKey('authorities')) {
      final authorities = payload['authorities'];
      if (authorities is List && authorities.isNotEmpty) {
        final authority = authorities[0] as String;
        // Remove 'ROLE_' prefix if present
        return authority.replaceAll('ROLE_', '');
      }
    }

    return null;
  }

  /// Extract username from JWT token
  static String? extractUsername(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;

    if (payload.containsKey('sub')) {
      return payload['sub'] as String?;
    }
    if (payload.containsKey('username')) {
      return payload['username'] as String?;
    }

    return null;
  }

  /// Extract branchId from JWT token
  static String? extractBranchId(String token) {
    final payload = decodePayload(token);
    return payload?['branchId'] as String?;
  }

  /// Extract businessId from JWT token
  static String? extractBusinessId(String token) {
    final payload = decodePayload(token);
    return payload?['businessId'] as String?;
  }
}




