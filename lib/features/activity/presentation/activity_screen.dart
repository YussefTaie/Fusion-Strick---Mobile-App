import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_skeleton.dart';

/// Scrollable alerts feed showing real-time backend alerts.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Alerts Feed', style: AppTextStyles.headlineMedium),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.invalidate(alertsProvider),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            alertsAsync.when(
              loading: () => SliverPadding(
                padding: AppSpacing.screenPadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: LoadingSkeleton.card(),
                    ),
                    childCount: 6,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Failed to load alerts',
                          style: AppTextStyles.headlineSmall
                              .copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(err.toString(),
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(alertsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline,
                                size: 48, color: AppColors.success),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('All Clear',
                              style: AppTextStyles.headlineSmall
                                  .copyWith(color: AppColors.success)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('No security alerts at this time.',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) {
                        final alert = alerts[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AlertFeedCard(alert: alert),
                        );
                      },
                      childCount: alerts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual alert card for the feed — richer than the home preview.
class _AlertFeedCard extends StatelessWidget {
  const _AlertFeedCard({required this.alert});

  final dynamic alert; // AlertModel

  StatusType get _statusType {
    switch (alert.severity) {
      case 'critical':
        return StatusType.danger;
      case 'high':
        return StatusType.warning;
      case 'medium':
        return StatusType.info;
      default:
        return StatusType.success;
    }
  }

  Color get _accentColor {
    switch (alert.severity) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: type + severity badge
          Row(
            children: [
              // Accent dot
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            alert.attackType,
                            style: AppTextStyles.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          label: alert.severity.toUpperCase(),
                          type: _statusType,
                        ),
                      ],
                    ),
                    if (alert.message != null && alert.message!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        alert.message!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Meta row: IP + timestamp
          Row(
            children: [
              const Icon(Icons.language_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(alert.sourceIp, style: AppTextStyles.bodySmall),
              const SizedBox(width: AppSpacing.lg),
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppFormatters.timeAgo(alert.timestamp),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
