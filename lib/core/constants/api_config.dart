/// Single source of truth for backend API configuration.
///
/// Change [baseUrl] here to point the entire app at a different backend.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API.
  ///
  /// For Android emulator:   http://10.0.2.2:5000
  /// For iOS simulator:      http://127.0.0.1:5000
  /// For physical device:    http://<YOUR_LOCAL_IP>:5000
  static const String baseUrl = 'http://10.213.142.160:5000';

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
  static const String pentestScans = '/pentest/scans';
  static const String autoResponseStatus = '/auto-response/status';
}
