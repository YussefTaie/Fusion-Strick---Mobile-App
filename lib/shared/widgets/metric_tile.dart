import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import 'app_card.dart';

/// A compact card displaying a single metric with icon, label, and value.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.trend,
    this.glowColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final String? trend;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return AppCard(
      glowColor: glowColor,
      padding: AppSpacing.cardPaddingSmall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with glow background
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),

          // Value
          Text(value, style: AppTextStyles.metricMedium),
          const SizedBox(height: AppSpacing.xs),

          // Label
          Text(label, style: AppTextStyles.labelMedium),

          // Optional trend
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              trend!,
              style: AppTextStyles.labelSmall.copyWith(
                color: trend!.startsWith('+')
                    ? AppColors.danger
                    : AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
