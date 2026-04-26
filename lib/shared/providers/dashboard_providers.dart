import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_config.dart';
import '../../services/api_service.dart';
import '../models/alert_model.dart';
import '../models/dashboard_stats.dart';
import '../models/detection_model.dart';
import '../models/health_status.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// KPI HELPER FUNCTIONS — aligned with web dashboard SOC logic
// (Reference: useSocData.js → deriveThreatState / sidebarCounts / socMappers.js)
// ═══════════════════════════════════════════════════════════════════════════════

/// Count only unread / open alerts.
///
/// Web equivalent: `sidebarCounts.alerts = alerts.filter(a => !a.is_read).length`
int calculateOpenAlerts(List<dynamic> alertsData) {
  return alertsData
      .where((a) {
        // Primary: use is_read field from backend (boolean or int 0/1)
        final isRead = a['is_read'];
        if (isRead != null) {
          if (isRead is bool) return !isRead;
          if (isRead is int) return isRead == 0;
          if (isRead is String) return isRead.toLowerCase() != 'true';
        }
        // Fallback: treat ATTACK/BLOCK/SUSPICIOUS/MALWARE as active
        final type = (a['type'] ?? '').toString().toUpperCase();
        return type == 'ATTACK' || type == 'BLOCK' ||
               type == 'SUSPICIOUS' || type == 'MALWARE';
      })
      .length;
}

/// Weighted threat score aligned with web's `deriveThreatState()`.
///
/// Web formula:
///   riskScore = ATTACK_count * 18 + SUSPICIOUS_count * 10 + unreadAlerts * 6
///   percent   = clamp(riskScore, 12, 100)
///
/// We normalize to 0.0–1.0 for mobile widget consumption.
double calculateThreatScore(List<dynamic> detectionsData, int unreadAlerts) {
  final attackCount = detectionsData
      .where((d) => (d['result'] ?? '').toString().toUpperCase() == 'ATTACK')
      .length;
  final suspiciousCount = detectionsData
      .where((d) => (d['result'] ?? '').toString().toUpperCase() == 'SUSPICIOUS')
      .length;

  final rawScore =
      (attackCount * 18) + (suspiciousCount * 10) + (unreadAlerts * 6);
  final percent = math.max(12, math.min(100, rawScore));

  return percent / 100.0;
}

/// Determine top attack vector from recent detections only.
///
/// Web equivalent: `deriveAttackDistribution()` operating on latest ~20 detections
/// Mobile uses latest 50 for a slightly broader window.
({String type, int count}) calculateTopAttack(List<dynamic> detectionsData) {
  // Take only the most recent detections (already ordered by backend, newest first)
  final recentDetections = detectionsData.take(50);

  final attackCounts = <String, int>{};
  for (final d in recentDetections) {
    final attackType = (d['attack_type'] ?? 'UNKNOWN').toString().toUpperCase();
    final result = (d['result'] ?? '').toString().toUpperCase();

    // Skip benign and normal — only count actual threats
    if (attackType == 'BENIGN' || result == 'NORMAL') continue;

    attackCounts[attackType] = (attackCounts[attackType] ?? 0) + 1;
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

/// Count critical-level detections: ATTACK, BLOCK, or MALWARE.
///
/// Sourced from detections (richer signal than alerts).
int calculateCriticalCount(List<dynamic> detectionsData) {
  const criticalResults = {'ATTACK', 'BLOCK', 'MALWARE'};
  return detectionsData
      .where((d) =>
          criticalResults.contains(
            (d['result'] ?? '').toString().toUpperCase(),
          ))
      .length;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD STATS — aggregated from /alerts + /detections (SOC-aligned)
// ═══════════════════════════════════════════════════════════════════════════════

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final api = ApiService.instance;

  try {
    // Fetch alerts and detections in parallel
    final results = await Future.wait([
      api.get(ApiConfig.alerts, queryParameters: {'limit': 200}),
      api.get(ApiConfig.detections, queryParameters: {'limit': 200}),
      api.get(ApiConfig.actions, queryParameters: {'limit': 200}),
    ]);

    final alertsData = results[0].data as List? ?? [];
    final detectionsData = results[1].data as List? ?? [];
    final actionsData = results[2].data as List? ?? [];

    // ── 1. Open / unread alerts (web: sidebarCounts.alerts) ──
    final openAlerts = calculateOpenAlerts(alertsData);

    // ── 2. Weighted threat score (web: deriveThreatState) ──
    final threatScore = calculateThreatScore(detectionsData, openAlerts);

    // ── 3. Top attack vector — recent detections only ──
    final topAttack = calculateTopAttack(detectionsData);

    // ── 4. Critical count from detections (ATTACK + BLOCK + MALWARE) ──
    final criticalCount = calculateCriticalCount(detectionsData);

    // ── Blocked actions count (unchanged) ──
    final blockedCount = actionsData
        .where(
            (a) => (a['action_type'] ?? '').toString().toUpperCase() == 'BLOCK')
        .length;

    return DashboardStats(
      threatScore: threatScore,
      totalAlerts: openAlerts, // Now reflects open/unread only
      criticalAlerts: criticalCount,
      blockedAttacks: blockedCount,
      activeHosts: 0, // Not tracked in mobile lite
      topAttackType: topAttack.type,
      topAttackCount: topAttack.count,
    );
  } catch (e) {
    debugPrint('[DashboardStats] Error fetching: $e');
    // Return empty stats on error
    return const DashboardStats(
      threatScore: 0,
      totalAlerts: 0,
      criticalAlerts: 0,
      blockedAttacks: 0,
      activeHosts: 0,
      topAttackType: 'N/A',
      topAttackCount: 0,
    );
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// ALERTS — from GET /alerts
// ═══════════════════════════════════════════════════════════════════════════════

final alertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final api = ApiService.instance;

  try {
    final response =
        await api.get(ApiConfig.alerts, queryParameters: {'limit': 50});
    final data = response.data as List? ?? [];

    return data.map((json) {
      final map = json as Map<String, dynamic>;
      // Map backend alert format to AlertModel
      final type = (map['type'] ?? '').toString().toUpperCase();
      String severity;
      if (type == 'ATTACK' || type == 'BLOCK') {
        severity = 'critical';
      } else if (type == 'SUSPICIOUS' || type == 'MALWARE') {
        severity = 'high';
      } else {
        severity = 'medium';
      }

      // Parse is_read status from backend
      final rawIsRead = map['is_read'];
      bool isRead = false;
      if (rawIsRead is bool) {
        isRead = rawIsRead;
      } else if (rawIsRead is int) {
        isRead = rawIsRead != 0;
      }

      return AlertModel(
        id: map['id']?.toString() ?? '',
        sourceIp: map['ip'] ?? 'unknown',
        attackType: map['type'] ?? 'UNKNOWN',
        severity: severity,
        confidence: 0.0, // Not in alert response
        timestamp: DateTime.tryParse(map['time']?.toString() ?? '') ??
            DateTime.now(),
        message: map['message'] as String?,
        isRead: isRead,
      );
    }).toList();
  } catch (e) {
    debugPrint('[Alerts] Error fetching: $e');
    return [];
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// LATEST ALERTS (for Home screen preview — max 5)
// ═══════════════════════════════════════════════════════════════════════════════

final latestAlertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final allAlerts = await ref.watch(alertsProvider.future);
  return allAlerts.take(5).toList();
});

// ═══════════════════════════════════════════════════════════════════════════════
// DETECTIONS — from GET /detections
// ═══════════════════════════════════════════════════════════════════════════════

final detectionsProvider = FutureProvider<List<DetectionModel>>((ref) async {
  final api = ApiService.instance;

  try {
    final response =
        await api.get(ApiConfig.detections, queryParameters: {'limit': 50});
    final data = response.data as List? ?? [];

    return data
        .map((json) => DetectionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('[Detections] Error fetching: $e');
    return [];
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// HEALTH — from GET /health
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// AUTO RESPONSE STATUS — from GET /auto-response/status
// ═══════════════════════════════════════════════════════════════════════════════

final autoResponseProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ApiService.instance;

  try {
    final response = await api.get(ApiConfig.autoResponseStatus);
    return response.data as Map<String, dynamic>;
  } catch (e) {
    debugPrint('[AutoResponse] Error fetching: $e');
    return {'enabled': false, 'error': e.toString()};
  }
});
