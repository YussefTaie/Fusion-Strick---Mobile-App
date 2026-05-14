import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../core/constants/api_config.dart';
import '../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents the three possible auth states.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isLoading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(const AuthState(status: AuthStatus.unknown, isLoading: true)) {
    _tryAutoLogin();
  }

  final _api = ApiService.instance;
  final _auth = AuthService.instance;

  /// Try to auto-login from stored token on app start.
  Future<void> _tryAutoLogin() async {
    try {
      final hasToken = await _auth.hasToken();
      if (!hasToken) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      // Validate token with /auth/me
      final response = await _api.get(ApiConfig.me);
      if (response.statusCode == 200) {
        final userData = response.data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        state = AuthState(status: AuthStatus.authenticated, user: user);
        debugPrint('[Auth] Auto-login successful: ${user.username}');
      } else {
        await _auth.clearSession();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('[Auth] Auto-login failed: $e');
      // Token might be expired or server unreachable
      // Keep stored token but mark as unauthenticated so user can retry
      await _auth.clearSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with identifier (username or email) + password.
  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _api.post(ApiConfig.login, data: {
        'identifier': identifier,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final userData = response.data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        await _auth.saveToken(token);
        await _auth.saveUserData(jsonEncode(userData));

        state = AuthState(status: AuthStatus.authenticated, user: user);
        debugPrint('[Auth] Login successful: ${user.username}');
        return true;
      } else {
        final error = response.data['error'] ?? 'Login failed';
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
        return false;
      }
    } catch (e) {
      String message = 'Connection failed. Check server & network.';
      if (e.toString().contains('401')) {
        message = 'Invalid credentials';
      } else if (e is DioException) {
        final uri = e.requestOptions.uri.toString();
        if (e.error is SocketException) {
          message = 'Network error: cannot reach $uri';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message = 'Timeout contacting $uri';
        } else if (e.response != null) {
          message = 'Server error ${e.response?.statusCode} at $uri';
        } else {
          message = 'Cannot reach server at $uri';
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      debugPrint('[Auth] Login error: $e');
      debugPrint('[Auth] Base URL in use: ${ApiConfig.baseUrl}');
      return false;
    }
  }

  /// Logout — clear token and reset state.
  Future<void> logout() async {
    await _auth.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
    debugPrint('[Auth] Logged out');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
