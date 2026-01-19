import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _emailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _accessTokenKey = 'access_token';
  static const _tokenTypeKey = 'token_type';
  static const _expiresInKey = 'expires_in';
  static const _tokenTimestampKey = 'token_timestamp'; // When token was saved
  static const _userTokenKey = 'USER_TOKEN';
  static const _memberNoKey = 'member_no';
  static const _memberNameKey = 'member_name';
  static const _memberEmailKey = 'member_email';
  static const _memberPhoneKey = 'member_phone';

  // Keys
  static const String _mfaTokenKey = 'mfa_token';
  static const String _authTokenKey = 'auth_token';

  /// MFA TOKEN
  static Future<void> saveMfaToken(String token) async {
    await _storage.write(key: _mfaTokenKey, value: token);
  }

  static Future<String?> getMfaToken() async {
    return await _storage.read(key: _mfaTokenKey);
  }

  static Future<void> deleteMfaToken() async {
    await _storage.delete(key: _mfaTokenKey);
  }

  /// AUTH TOKEN (for later)
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<Map<String, String?>> getCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    return {'email': email, 'password': password};
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  /// Save access token with timestamp
  static Future<void> saveAccessToken({
    required String accessToken,
    required String tokenType,
    required int expiresIn,
  }) async {
    // Save token
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
    await _storage.write(key: _expiresInKey, value: expiresIn.toString());
    
    // Save timestamp when token was stored
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _tokenTimestampKey, value: timestamp);
    
    // Print token for debugging
    print('🔑 ACCESS TOKEN SAVED:');
    print('📋 Token: $accessToken');
    print('⏰ Expires In: $expiresIn seconds');
    print('🕐 Saved At: ${DateTime.now()}');
    
    // Try to decode JWT if it's a JWT token
    try {
      final decoded = Jwt.parseJwt(accessToken);
      print('🔓 DECODED TOKEN:');
      print(decoded);
      
      if (decoded.containsKey('exp')) {
        final expTimestamp = decoded['exp'];
        final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
        print('⏰ Token Expires At: $expDate');
      }
    } catch (e) {
      print('⚠️ Token is not a JWT or cannot be decoded: $e');
    }
  }

  /// Get access token (returns null if expired)
  static Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return null;
    
    // Check if token is expired
    final isExpired = await isTokenExpired();
    if (isExpired) {
      print('⚠️ Token is expired!');
      return null;
    }
    
    return token;
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return true;

    // Method 1: Check using JWT expiry (if it's a JWT token)
    try {
      final decoded = Jwt.parseJwt(token);
      if (decoded.containsKey('exp')) {
        final expTimestamp = decoded['exp'];
        final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
        final isExpired = DateTime.now().isAfter(expDate);
        
        if (isExpired) {
          print('🔴 JWT Token expired at: $expDate');
        }
        
        return isExpired;
      }
    } catch (e) {
      print('⚠️ Not a JWT token, using timestamp method: $e');
    }

    // Method 2: Check using saved timestamp + expiresIn
    final timestampStr = await _storage.read(key: _tokenTimestampKey);
    final expiresInStr = await _storage.read(key: _expiresInKey);
    
    if (timestampStr == null || expiresInStr == null) {
      print('⚠️ No timestamp or expiresIn found, considering expired');
      return true;
    }

    try {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
      final expiresIn = int.parse(expiresInStr);
      final expiryTime = savedTime.add(Duration(seconds: expiresIn));
      
      final isExpired = DateTime.now().isAfter(expiryTime);
      
      if (isExpired) {
        print('🔴 Token expired at: $expiryTime');
        print('🕐 Current time: ${DateTime.now()}');
      } else {
        final timeLeft = expiryTime.difference(DateTime.now());
        print('✅ Token valid for: ${timeLeft.inMinutes} minutes');
      }
      
      return isExpired;
    } catch (e) {
      print('❌ Error checking expiry: $e');
      return true; // Consider expired if we can't check
    }
  }

  /// Get time until token expires (in seconds)
  static Future<int?> getTimeUntilExpiry() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return null;

    // Try JWT method first
    try {
      final decoded = Jwt.parseJwt(token);
      if (decoded.containsKey('exp')) {
        final expTimestamp = decoded['exp'];
        final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
        final secondsLeft = expDate.difference(DateTime.now()).inSeconds;
        return secondsLeft > 0 ? secondsLeft : 0;
      }
    } catch (e) {
      // Fall through to timestamp method
    }

    // Use timestamp method
    final timestampStr = await _storage.read(key: _tokenTimestampKey);
    final expiresInStr = await _storage.read(key: _expiresInKey);
    
    if (timestampStr == null || expiresInStr == null) return null;

    try {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
      final expiresIn = int.parse(expiresInStr);
      final expiryTime = savedTime.add(Duration(seconds: expiresIn));
      
      final secondsLeft = expiryTime.difference(DateTime.now()).inSeconds;
      return secondsLeft > 0 ? secondsLeft : 0;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _expiresInKey);
    await _storage.delete(key: _tokenTimestampKey);
    await _storage.delete(key: _mfaTokenKey);
  }

  // Save USER token (member details)
  static Future<void> saveUserToken(String token) async {
    await _storage.write(key: _userTokenKey, value: token);
  }

  static Future<String?> getUserToken() async {
    return await _storage.read(key: _userTokenKey);
  }

  /// Save member details
  static Future<void> saveMemberDetails(Map<String, dynamic> user) async {
    await _storage.write(key: _memberNoKey, value: user['memberNo'] ?? '');
    await _storage.write(key: _memberNameKey, value: user['fullName'] ?? '');
    await _storage.write(
      key: _memberEmailKey,
      value: user['emailAddress'] ?? '',
    );
    await _storage.write(
      key: _memberPhoneKey,
      value: user['phoneNumber'] ?? '',
    );
  }

  /// Get member details
  static Future<Map<String, String?>> getMemberDetails() async {
    final memberNo = await _storage.read(key: _memberNoKey);
    final name = await _storage.read(key: _memberNameKey);
    final email = await _storage.read(key: _memberEmailKey);
    final phone = await _storage.read(key: _memberPhoneKey);

    return {
      'memberNo': memberNo,
      'fullName': name,
      'emailAddress': email,
      'phoneNumber': phone,
    };
  }

  /// Check if user session is valid (has token and not expired)
  static Future<bool> hasValidSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return false;
    
    final isExpired = await isTokenExpired();
    return !isExpired;
  }
}