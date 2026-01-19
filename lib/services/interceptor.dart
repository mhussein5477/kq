import 'package:kq/services/secure_storage_service.dart';

/// API Token Interceptor
/// Add this check before making API calls to handle expired tokens
class ApiTokenInterceptor {
  /// Check token validity and throw exception if expired
  /// Use this before making API calls
  static Future<String> getValidTokenOrThrow() async {
    // Check if token exists
    final token = await SecureStorageService.getAccessToken();
    
    if (token == null) {
      throw TokenExpiredException('No access token found. Please login.');
    }

    // Check if token is expired
    final isExpired = await SecureStorageService.isTokenExpired();
    
    if (isExpired) {
      // Get time information for better error message
      final timeInfo = await _getExpiryInfo();
      throw TokenExpiredException(
        'Your session has expired. Please login again.',
        expiryInfo: timeInfo,
      );
    }

    return token;
  }

  /// Get expiry information for logging
  static Future<Map<String, dynamic>> _getExpiryInfo() async {
    final secondsLeft = await SecureStorageService.getTimeUntilExpiry();
    
    return {
      'secondsUntilExpiry': secondsLeft,
      'isExpired': secondsLeft != null && secondsLeft <= 0,
      'currentTime': DateTime.now().toIso8601String(),
    };
  }

  /// Check if token will expire soon (within 5 minutes)
  /// Use this to show warning to user
  static Future<bool> willExpireSoon({int warningMinutes = 5}) async {
    final seconds = await SecureStorageService.getTimeUntilExpiry();
    if (seconds == null) return true;
    
    return seconds <= (warningMinutes * 60);
  }
}

/// Custom exception for expired tokens
class TokenExpiredException implements Exception {
  final String message;
  final Map<String, dynamic>? expiryInfo;

  TokenExpiredException(this.message, {this.expiryInfo});

  @override
  String toString() => message;
}