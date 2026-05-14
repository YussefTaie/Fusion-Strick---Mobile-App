import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_config.dart';
import '../../services/api_service.dart';
import '../models/alert_model.dart';
import '../models/dashboard_stats.dart';
import '../models/detection_model.dart';
import '../models/health_status.dart';

bool _isReadAlert(Map<String, dynamic> alert) {
  final isRead = alert['is_read'];
  if (isRead is bool) return isRead;
  if (isRead is int) return isRead != 0;
  if (isRead is String) return isRead.toLowerCase() == 'true';
  return false;
}

int calculateOpenAlerts(List<dynamic> alertsData) {
  return alertsData.where((raw) {
    final alert = raw as Map<String, dynamic>;
    final status = (alert['status'] ?? '').toString().toLowerCase();
    return !_isReadAlert(alert) && status != 'resolved';
  }).length;
}

String _normalizeResult(String value, {String attackType = ''}) {
  final normalized = value.trim().toUpperCase();
  final attackNormalized = attackType.trim().toUpperCase();

  if (const {'ATTACK', 'MALICIOUS', 'ANOMALY', 'CRITICAL', 'HIGH'}
      .contains(normalized)) {
    return 'ATTACK';
  }
  if (const {'SUSPICIOUS', 'WARNING', 'MEDIUM'}.contains(normalized)) {
    return 'SUSPICIOUS';
  }
  if (const {'NORMAL', 'BENIGN', 'CLEAN', 'OK'}.contains(normalized)) {
    return 'NORMAL';
  }
  if (attackNormalized.isNotEmpty &&
      !const {'BENIGN', 'NORMAL', 'OK', 'CLEAN', 'NONE'}
          .contains(attackNormalized)) {
    return 'ATTACK';
  }
  return 'NORMAL';
}

String _normalizeAttackLabel(String value, {String result = ''}) {
  final cleaned = value
      .replaceAll(RegExp(r'\(conf=.*?\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'^(ML|ML\+ISO):', caseSensitive: false), '')
      .replaceAll(RegExp(r'[_\-/]+'), ' ')
      .trim();
  final folded = cleaned.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  if (const {'', 'BENIGN', 'NORMAL', 'OK', 'CLEAN', 'NONE'}.contains(folded)) {
    return 'BENIGN';
  }

  const aliases = <MapEntry<List<String>, String>>[
    MapEntry(
      ['DDOS', 'D DOS', 'DOS HULK', 'DOS GOLDENEYE', 'SLOWLORIS', 'SLOWHTTPTEST', 'HEARTBLEED'],
      'DDoS',
    ),
    MapEntry(['PORTSCAN', 'PORT SCAN', 'SCAN'], 'PortScan'),
    MapEntry(['BRUTEFORCE', 'BRUTE FORCE', 'FTP PATATOR', 'SSH PATATOR', 'PATATOR'], 'BruteForce'),
    MapEntry(['BOT', 'BOTNET'], 'Bot'),
    MapEntry(['WEBATTACK', 'WEB ATTACK', 'SQL INJECTION', 'XSS'], 'WebAttack'),
    MapEntry(['INFILTRATION'], 'Infiltration'),
    MapEntry(['MALWARE', 'RANSOMWARE', 'BEACON'], 'Malware'),
  ];

  for (final entry in aliases) {
    if (entry.key.any((alias) => folded.contains(alias))) return entry.value;
  }

  if (_normalizeResult(result, attackType: folded) == 'NORMAL') return 'BENIGN';
  return cleaned.isEmpty ? 'Unknown' : cleaned;
}

double calculateThreatScore(
  List<dynamic> detectionsData,
  List<dynamic> alertsData,
  List<dynamic> pentestFindings,
) {
  final normalizedResults = detectionsData.map((raw) {
    final detection = raw as Map<String, dynamic>;
    final attack =
        (detection['attack_type'] ?? detection['prediction'] ?? detection['label'] ?? '')
            .toString();
    return _normalizeResult((detection['result'] ?? detection['label'] ?? '').toString(),
        attackType: attack);
  }).toList();

  final total = normalizedResults.length;
  final attackCount = normalizedResults.where((r) => r == 'ATTACK').length;
  final suspiciousCount = normalizedResults.where((r) => r == 'SUSPICIOUS').length;

  final maliciousWeight = attackCount + (suspiciousCount * 0.5);
  final detectionRisk = total > 0 ? (maliciousWeight / total) * 100.0 : 0.0;
  final alertRisk = math.min(calculateOpenAlerts(alertsData) * 3, 15).toDouble();
  final pentestRiskRaw = pentestFindings.fold<double>(
    0,
    (sum, raw) => sum + ((raw as Map<String, dynamic>)['risk_score'] as num? ?? 0).toDouble(),
  );
  final pentestRisk = math.min(pentestRiskRaw * 0.05, 10.0);

  final percent =
      math.min(100, math.max(0, (detectionRisk + alertRisk + pentestRisk).round()));
  return percent / 100.0;
}

({String type, int count}) calculateTopAttack(List<dynamic> detectionsData) {
  final attackCounts = <String, int>{};

  for (final raw in detectionsData) {
    final detection = raw as Map<String, dynamic>;
    final rawAttack =
        (detection['attack_type'] ?? detection['prediction'] ?? detection['label'] ?? '')
            .toString();
    final result = _normalizeResult((detection['result'] ?? detection['label'] ?? '').toString(),
        attackType: rawAttack);
    final label = _normalizeAttackLabel(rawAttack, result: result);

    if (result == 'NORMAL' || label == 'BENIGN') continue;
    attackCounts[label] = (attackCounts[label] ?? 0) + 1;
  }

  String topType = 'None';
  int topCount = 0;
  attackCounts.forEach((type, count) {
    if (count > topCount) {
      topType = type;
      topCount = count;
    }
  });

  return (type: topType, count: topCount);
}

int calculateAttackDistributionTotal(List<dynamic> detectionsData) {
  int total = 0;
  for (final raw in detectionsData) {
    final detection = raw as Map<String, dynamic>;
    final rawAttack =
        (detection['attack_type'] ?? detection['prediction'] ?? detection['label'] ?? '')
            .toString();
    final result = _normalizeResult((detection['result'] ?? detection['label'] ?? '').toString(),
        attackType: rawAttack);
    final label = _normalizeAttackLabel(rawAttack, result: result);
    if (result == 'NORMAL' || label == 'BENIGN') continue;
    total++;
  }
  return total;
}

int calculateCriticalCount(List<dynamic> detectionsData) {
  return detectionsData.where((raw) {
    final detection = raw as Map<String, dynamic>;
    final attack =
        (detection['attack_type'] ?? detection['prediction'] ?? detection['label'] ?? '')
            .toString();
    return _normalizeResult((detection['result'] ?? detection['label'] ?? '').toString(),
            attackType: attack) ==
        'ATTACK';
  }).length;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final api = ApiService.instance;

  try {
    final results = await Future.wait([
      api.get(ApiConfig.alerts, queryParameters: {'limit': 12}),
      api.get(ApiConfig.detections,
          queryParameters: {'limit': 50, 'include_contained': true}),
      api.get(ApiConfig.blockedIps),
      api.get('/pentest/findings', queryParameters: {'limit': 20}),
    ]);

    final alertsData = results[0].data as List? ?? [];
    final detectionsData = results[1].data as List? ?? [];
    final blockedIpsData = results[2].data as List? ?? [];
    final pentestFindings = results[3].data as List? ?? [];

    final openAlerts = calculateOpenAlerts(alertsData);
    final threatScore =
        calculateThreatScore(detectionsData, alertsData, pentestFindings);
    final topAttack = calculateTopAttack(detectionsData);
    final topAttackTotal = calculateAttackDistributionTotal(detectionsData);
    final criticalCount = calculateCriticalCount(detectionsData);

    return DashboardStats(
      threatScore: threatScore,
      totalAlerts: alertsData.length,
      criticalAlerts: criticalCount,
      blockedAttacks: blockedIpsData.length,
      activeHosts: 0,
      topAttackType: topAttack.type,
      topAttackCount: topAttack.count,
      topAttackTotal: topAttackTotal,
    );
  } catch (e) {
    debugPrint('[DashboardStats] Error fetching: $e');
    return const DashboardStats(
      threatScore: 0,
      totalAlerts: 0,
      criticalAlerts: 0,
      blockedAttacks: 0,
      activeHosts: 0,
      topAttackType: 'N/A',
      topAttackCount: 0,
      topAttackTotal: 0,
    );
  }
});

final alertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final api = ApiService.instance;

  try {
    final response =
        await api.get(ApiConfig.alerts, queryParameters: {'limit': 12});
    final data = response.data as List? ?? [];

    return data.map((json) {
      final map = json as Map<String, dynamic>;
      final type = (map['type'] ?? '').toString().toUpperCase();
      String severity;
      if (type == 'ATTACK' || type == 'BLOCK') {
        severity = 'critical';
      } else if (type == 'SUSPICIOUS' || type == 'MALWARE') {
        severity = 'high';
      } else {
        severity = 'medium';
      }

      return AlertModel(
        id: map['id']?.toString() ?? '',
        sourceIp: map['ip'] ?? 'unknown',
        attackType: map['type'] ?? 'UNKNOWN',
        severity: severity,
        confidence: 0.0,
        timestamp:
            DateTime.tryParse(map['time']?.toString() ?? '') ?? DateTime.now(),
        message: map['message'] as String?,
        isRead: _isReadAlert(map),
      );
    }).toList();
  } catch (e) {
    debugPrint('[Alerts] Error fetching: $e');
    return [];
  }
});

final latestAlertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final allAlerts = await ref.watch(alertsProvider.future);
  return allAlerts.take(5).toList();
});

final detectionsProvider = FutureProvider<List<DetectionModel>>((ref) async {
  final api = ApiService.instance;

  try {
    final response = await api.get(
      ApiConfig.detections,
      queryParameters: {'limit': 50, 'include_contained': true},
    );
    final data = response.data as List? ?? [];

    return data
        .map((json) => DetectionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('[Detections] Error fetching: $e');
    return [];
  }
});

final healthProvider = FutureProvider<HealthStatus>((ref) async {
  final api = ApiService.instance;

  try {
    final response = await api.get(ApiConfig.health);
    return HealthStatus.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[Health] Error fetching: $e');
    return const HealthStatus(
      status: 'unreachable',
      modelMode: 'unknown',
      dbStatus: 'unknown',
      autoResponseEnabled: false,
      pentestMode: 'unknown',
    );
  }
});

final autoResponseProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ApiService.instance;

  try {
    final response = await api.get(ApiConfig.autoResponseStatus);
    return response.data as Map<String, dynamic>;
  } catch (e) {
    debugPrint('[AutoResponse] Error fetching: $e');
    return {'enabled': false, 'error': e.toString()};
  }
});
