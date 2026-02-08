import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is SocketException || error is http.ClientException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is TimeoutException) {
      return 'The server is taking too long to respond. Please check your connection and try again.';
    } else if (error is http.Response) {
      return _handleHttpResponse(error);
    } else if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.replaceFirst('Exception: ', '');
      }
      return msg;
    }
    return 'An unexpected error occurred. Please try again later.';
  }

  static String _handleHttpResponse(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return _parseErrorMessage(response.body, 'Invalid request. Please check your input.');
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested information could not be found.';
      case 429:
        return 'Too many requests. Please slow down and try again.';
      case 500:
        return 'Something went wrong on our end. Our team is notified!';
      case 503:
        return 'Server is currently undergoing maintenance. Please try again soon.';
      default:
        return _parseErrorMessage(response.body, 'Something went wrong (Error ${response.statusCode})');
    }
  }

  static String _parseErrorMessage(String body, String defaultMessage) {
    if (body.isEmpty) return defaultMessage;
    
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        String? message;
        if (data.containsKey('message')) message = data['message'];
        else if (data.containsKey('error')) message = data['error'];
        else if (data.containsKey('details')) message = data['details'];

        if (message != null) {
          // Relatable mappings for common backend messages
          final lowerMsg = message.toLowerCase();
          if (lowerMsg.contains('invalid credentials') || lowerMsg.contains('bad credentials')) {
            return 'Incorrect email or password. Please try again.';
          }
          if (lowerMsg.contains('insufficient stock')) {
            return 'Not enough stock available for one or more items.';
          }
          if (lowerMsg.contains('user already exists')) {
            return 'An account with this email already exists.';
          }
          if (lowerMsg.contains('product not found')) {
            return 'We couldn\'t find that product. Please check the barcode.';
          }
          return message;
        }
      }
      return body;
    } catch (_) {
      // If it's not JSON, it might be a plain string from the backend
      if (body.length < 100) return body;
      return defaultMessage;
    }
  }

  static String formatException(dynamic e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.replaceFirst('Exception: ', '');
    }
    return msg;
  }

  static bool isConnectionError(dynamic error) {
    if (error == null) return false;
    
    final message = getMessage(error).toLowerCase();
    
    return message.contains('no internet') || 
           message.contains('taking too long') ||
           message.contains('timeout') ||
           message.contains('connection refused') ||
           message.contains('socketexception') ||
           message.contains('clientexception') ||
           message.contains('host lookup');
  }
}
