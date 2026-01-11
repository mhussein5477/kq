import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _emailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _accessTokenKey = 'access_token';
  static const _tokenTypeKey = 'token_type';
  static const _expiresInKey = 'expires_in';
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

  static Future<void> saveAccessToken({
    required String accessToken,
    required String tokenType,
    required int expiresIn,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
    await _storage.write(key: _expiresInKey, value: expiresIn.toString());
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _expiresInKey);
    await _storage.delete(key: 'mfa_token'); // cleanup
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
}
