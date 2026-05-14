import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/models/dashboard_stats.dart';
import '../../../shared/providers/dashboard_providers.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import 'widgets/alert_preview_card.dart';
import 'widgets/threat_score_ring.dart';
import 'widgets/top_attack_card.dart';

/// The main dashboard screen showing threat overview and recent alerts.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(latestAlertsProvider);
      ref.invalidate(alertsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final alertsAsync = ref.watch(latestAlertsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Fusion Strike', style: AppTextStyles.headlineMedium),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    ref.invalidate(dashboardStatsProvider);
                    ref.invalidate(latestAlertsProvider);
                    ref.invalidate(alertsProvider);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),

            // ── Body ──
            SliverPadding(
              padding: AppSpacing.screenPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Threat Score ──
                  statsAsync.when(
                    skipLoadingOnReload: true,
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxxl),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => _buildErrorWidget(err, ref),
                    data: (stats) => ThreatScoreRing(score: stats.threatScore),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Stats Grid ──
                  statsAsync.when(
                    skipLoadingOnReload: true,
                    loading: () => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.35,
                      children: List.generate(
                        4,
                        (_) => const LoadingSkeleton.card(),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stats) => _buildStatsGrid(stats),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Top Attack ──
                  statsAsync.when(
                    skipLoadingOnReload: true,
                    loading: () => const LoadingSkeleton.card(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stats) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Top Attack Vector'),
                        TopAttackCard(
                          attackType: stats.topAttackType,
                          count: stats.topAttackCount,
                          total: stats.totalAlerts > 0
                              ? stats.totalAlerts
                              : stats.topAttackCount + 1,
                        ),
                      ],
                    ),
                  ),

                  // ── Latest Alerts ──
                  const SectionHeader(
                    title: 'Latest Alerts',
                    trailing: 'View All',
                  ),
                  alertsAsync.when(
                    skipLoadingOnReload: true,
                    loading: () => Column(
                      children: List.generate(
                        3,
                        (_) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: LoadingSkeleton.card(),
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Could not load alerts: $err',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                    data: (alerts) {
                      if (alerts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              'No recent alerts.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: alerts
                            .map(
                              (alert) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: AlertPreviewCard(alert: alert),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        MetricTile(
          icon: Icons.warning_amber_rounded,
          label: 'Total Alerts',
          value: AppFormatters.compactNumber(stats.totalAlerts),
          iconColor: AppColors.warning,
        ),
        MetricTile(
          icon: Icons.error_outline_rounded,
          label: 'Critical',
          value: stats.criticalAlerts.toString(),
          iconColor: AppColors.danger,
          glowColor: stats.criticalAlerts > 0 ? AppColors.danger : null,
        ),
        MetricTile(
          icon: Icons.shield_outlined,
          label: 'Blocked',
          value: AppFormatters.compactNumber(stats.blockedAttacks),
          iconColor: AppColors.success,
        ),
        MetricTile(
          icon: Icons.speed_rounded,
          label: 'Threat Level',
          value: AppFormatters.percentage(stats.threatScore),
          iconColor: stats.threatScore >= 0.5
              ? AppColors.danger
              : AppColors.success,
        ),
      ],
    );
  }

  Widget _buildErrorWidget(Object err, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Cannot connect to server',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            err.toString(),
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(latestAlertsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
