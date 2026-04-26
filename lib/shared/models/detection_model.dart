/// Detection model matching backend GET /detections response rows.
///
/// Fields: id, src_ip, result, attack_type, confidence, iso_flag, detected_at
class DetectionModel {
  const DetectionModel({
    required this.id,
    required this.srcIp,
    required this.result,
    required this.attackType,
    required this.confidence,
    required this.isoFlag,
    required this.detectedAt,
  });

  final int id;
  final String srcIp;
  final String result;      // "ATTACK" | "SUSPICIOUS" | "NORMAL"
  final String attackType;  // "DDoS", "PortScan", etc.
  final double confidence;
  final int isoFlag;
  final DateTime detectedAt;

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      id: json['id'] as int? ?? 0,
      srcIp: json['src_ip'] as String? ?? 'unknown',
      result: json['result'] as String? ?? 'UNKNOWN',
      attackType: json['attack_type'] as String? ?? 'UNKNOWN',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isoFlag: json['iso_flag'] as int? ?? 0,
      detectedAt: DateTime.tryParse(json['detected_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Map result to severity for UI display.
  String get severity {
    switch (result) {
      case 'ATTACK':
        return confidence >= 0.85 ? 'critical' : 'high';
      case 'SUSPICIOUS':
        return 'medium';
      default:
        return 'low';
    }
  }
}
