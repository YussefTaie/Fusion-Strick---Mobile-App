/// Backend health response model matching GET /health.
class HealthStatus {
  const HealthStatus({
    required this.status,
    required this.modelMode,
    required this.dbStatus,
    required this.autoResponseEnabled,
    required this.pentestMode,
  });

  final String status;          // "ok"
  final String modelMode;       // "multiclass" | "binary"
  final String dbStatus;        // "ok" | "unavailable"
  final bool autoResponseEnabled;
  final String pentestMode;     // "external" | "internal"

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      modelMode: json['model_mode'] as String? ?? 'unknown',
      dbStatus: json['db_status'] as String? ?? 'unknown',
      autoResponseEnabled: json['auto_response_enabled'] as bool? ?? false,
      pentestMode: json['pentest_mode'] as String? ?? 'unknown',
    );
  }

  bool get isHealthy => status == 'ok';
  bool get isDbOk => dbStatus == 'ok';
}
