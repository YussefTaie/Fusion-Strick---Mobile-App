/// Aggregated dashboard statistics for the Home screen.
class DashboardStats {
  const DashboardStats({
    required this.threatScore,
    required this.totalAlerts,
    required this.criticalAlerts,
    required this.blockedAttacks,
    required this.activeHosts,
    required this.topAttackType,
    required this.topAttackCount,
    required this.topAttackTotal,
  });

  final double threatScore; // 0.0 – 1.0
  final int totalAlerts;
  final int criticalAlerts;
  final int blockedAttacks;
  final int activeHosts;
  final String topAttackType;
  final int topAttackCount;
  final int topAttackTotal;
}
