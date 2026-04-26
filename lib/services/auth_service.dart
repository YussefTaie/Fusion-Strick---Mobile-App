import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages JWT token persistence using platform-secure storage.
///
/// Tokens are stored encrypted via flutter_secure_storage (Keychain on iOS,
/// EncryptedSharedPreferences on Android).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_data';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _cachedToken;

  /// Store JWT token securely.
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
    debugPrint('[AuthService] Token saved');
  }

  /// Retrieve stored JWT token.
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// Store user data as JSON string.
  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Retrieve stored user data JSON.
  Future<String?> getUserData() async {
    return _storage.read(key: _userKey);
  }

  /// Clear all session data (logout).
  Future<void> clearSession() async {
    _cachedToken = null;
    await _storage.deleteAll();
    debugPrint('[AuthService] Session cleared');
  }

  /// Check if a token exists (quick check without validation).
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
