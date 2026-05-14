import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Single source of truth for backend API configuration.
///
/// Change [baseUrl] here to point the entire app at a different backend.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API.
  ///
  /// You can override at build/run time:
  /// --dart-define=API_BASE_URL=http://<YOUR_LOCAL_IP>:5000
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Default base URL:
  /// Android emulator     => 10.0.2.2
  /// iOS / others         => 127.0.0.1
  ///
  /// If you run on emulator, pass:
  /// --dart-define=API_BASE_URL=http://10.0.2.2:5000
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) return 'http://127.0.0.1:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://127.0.0.1:5000';
  }

  /// Request timeout in milliseconds.
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;

  // ── Endpoint Paths ──
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String health = '/health';
  static const String alerts = '/alerts';
  static const String detections = '/detections';
  static const String actions = '/actions';
  static const String blockedIps = '/blocked-ips';
  static const String stats = '/stats';
  static const String pentestScans = '/pentest/scans';
  static const String autoResponseStatus = '/auto-response/status';
}
