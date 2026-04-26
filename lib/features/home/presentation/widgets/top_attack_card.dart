import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_card.dart';

/// Card showing the most prevalent attack vector.
class TopAttackCard extends StatelessWidget {
  const TopAttackCard({
    super.key,
    required this.attackType,
    required this.count,
    required this.total,
  });

  final String attackType;
  final int count;
  final int total;

  double get _percentage => total > 0 ? count / total : 0;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attackType, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.compactNumber(count)} detections',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.percentage(_percentage),
                style: AppTextStyles.metricMedium.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _percentage,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
