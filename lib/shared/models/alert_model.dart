/// Model representing a security alert from the IDS/IPS system.
class AlertModel {
  const AlertModel({
    required this.id,
    required this.sourceIp,
    required this.attackType,
    required this.severity,
    required this.confidence,
    required this.timestamp,
    this.destinationIp,
    this.protocol,
    this.message,
    this.isRead = false,
  });

  final String id;
  final String sourceIp;
  final String attackType;
  final String severity; // 'critical', 'high', 'medium', 'low'
  final double confidence;
  final DateTime timestamp;
  final String? destinationIp;
  final String? protocol;
  final String? message;
  final bool isRead; // Tracks read/acknowledged status (maps to backend is_read)
}
