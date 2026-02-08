import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/error_handler.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  String? accessToken;
  static const Duration timeout = Duration(seconds: 30);

  void setAccessToken(String token) {
    accessToken = token;
  }

  Map<String, String> get headers {
    final headers = {'Content-Type': 'application/json'};
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;
      if (body.isEmpty) return {};
      
      final bodyText = body.trim();
      try {
        if (bodyText.startsWith('{') || bodyText.startsWith('[')) {
          return jsonDecode(bodyText);
        }
        // Handle JSON strings or plain text
        if (bodyText.startsWith('"') && bodyText.endsWith('"')) {
          return jsonDecode(bodyText);
        }
        return bodyText;
      } catch (e) {
        return bodyText;
      }
    } else {
      throw response; // Throw the response to be handled by ErrorHandler
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getMessage(e));
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getMessage(e));
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getMessage(e));
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getMessage(e));
    }
  }

  Future<dynamic> postWithParams(
    String endpoint,
    Map<String, String> params,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
      final response = await http
          .post(
            uri,
            headers: headers,
          )
          .timeout(timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception(ErrorHandler.getMessage(e));
    }
  }
}




