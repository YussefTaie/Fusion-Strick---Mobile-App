import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_skeleton.dart';

/// System status screen showing backend health, AI/DB status, and connectivity.
class SystemStatusScreen extends ConsumerWidget {
  const SystemStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);
    final autoResponseAsync = ref.watch(autoResponseProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text('System Status', style: AppTextStyles.headlineMedium),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    ref.invalidate(healthProvider);
                    ref.invalidate(autoResponseProvider);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            SliverPadding(
              padding: AppSpacing.screenPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),

                  // ── Overall Status Banner ──
                  healthAsync.when(
                    loading: () => const LoadingSkeleton.card(),
                    error: (err, _) =>
                        _StatusBanner(isHealthy: false, errorMsg: '$err'),
                    data: (health) =>
                        _StatusBanner(isHealthy: health.isHealthy),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Status Grid ──
                  Text('Services', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.md),

                  healthAsync.when(
                    loading: () => Column(
                      children: List.generate(
                        4,
                        (_) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: LoadingSkeleton.card(),
                        ),
                      ),
                    ),
                    error: (err, _) => _buildErrorCard(err.toString(), ref),
                    data: (health) => Column(
                      children: [
                        _ServiceCard(
                          icon: Icons.api_rounded,
                          title: 'API Server',
                          status: health.isHealthy ? 'Online' : 'Offline',
                          statusType: health.isHealthy
                              ? StatusType.success
                              : StatusType.danger,
                          detail: 'Port 5000',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ServiceCard(
                          icon: Icons.storage_rounded,
                          title: 'Database',
                          status: health.isDbOk ? 'Connected' : 'Unavailable',
                          statusType: health.isDbOk
                              ? StatusType.success
                              : StatusType.danger,
                          detail: 'PostgreSQL',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ServiceCard(
                          icon: Icons.psychology_rounded,
                          title: 'AI Model',
                          status: 'Active',
                          statusType: StatusType.success,
                          detail: health.modelMode == 'multiclass'
                              ? 'Multi-class XGBoost'
                              : 'Binary XGBoost',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ServiceCard(
                          icon: Icons.security_rounded,
                          title: 'Pentest Engine',
                          status: health.pentestMode.toUpperCase(),
                          statusType: StatusType.info,
                          detail: 'Mode: ${health.pentestMode}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Auto Response ──
                  Text('Auto Response', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.md),

                  autoResponseAsync.when(
                    loading: () => const LoadingSkeleton.card(),
                    error: (err, _) => _buildErrorCard(err.toString(), ref),
                    data: (arData) {
                      final enabled = arData['enabled'] == true;
                      return _ServiceCard(
                        icon: Icons.auto_fix_high_rounded,
                        title: 'Automated Response',
                        status: enabled ? 'Enabled' : 'Disabled',
                        statusType:
                            enabled ? StatusType.success : StatusType.warning,
                        detail: enabled
                            ? 'Auto-blocking active threats'
                            : 'Manual mode — no auto actions',
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Connectivity Check ──
                  Text('Connectivity', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.md),

                  healthAsync.when(
                    loading: () => const LoadingSkeleton.card(),
                    error: (err, _) => _ServiceCard(
                      icon: Icons.wifi_off_rounded,
                      title: 'API Connection',
                      status: 'Unreachable',
                      statusType: StatusType.danger,
                      detail: 'Cannot connect to backend server',
                    ),
                    data: (_) => _ServiceCard(
                      icon: Icons.wifi_rounded,
                      title: 'API Connection',
                      status: 'Connected',
                      statusType: StatusType.success,
                      detail: 'Latency normal',
                    ),
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

  Widget _buildErrorCard(String error, WidgetRef ref) {
    return AppCard(
      glowColor: AppColors.danger,
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 32, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Connection Error',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger)),
          const SizedBox(height: AppSpacing.xs),
          Text(error,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(healthProvider);
              ref.invalidate(autoResponseProvider);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isHealthy, this.errorMsg});

  final bool isHealthy;
  final String? errorMsg;

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.success : AppColors.danger;

    return AppCard(
      glowColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'All Systems Operational' : 'System Issues Detected',
                  style: AppTextStyles.headlineSmall.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  isHealthy
                      ? 'All services running normally.'
                      : errorMsg ?? 'One or more services are degraded.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.statusType,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String status;
  final StatusType statusType;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(detail, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          StatusBadge(label: status, type: statusType),
        ],
      ),
    );
  }
}
