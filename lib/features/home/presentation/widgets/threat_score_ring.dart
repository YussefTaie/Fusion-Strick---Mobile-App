import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';

/// Large circular widget displaying the current threat level.
///
/// The ring color shifts from green → yellow → red based on [score].
class ThreatScoreRing extends StatelessWidget {
  const ThreatScoreRing({super.key, required this.score});

  /// Threat score from 0.0 (safe) to 1.0 (critical).
  final double score;

  Color get _ringColor {
    if (score >= 0.75) return AppColors.danger;
    if (score >= 0.50) return AppColors.warning;
    return AppColors.success;
  }

  String get _label {
    if (score >= 0.75) return 'CRITICAL';
    if (score >= 0.50) return 'ELEVATED';
    if (score >= 0.25) return 'MODERATE';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _ringColor.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircularPercentIndicator(
              radius: 80,
              lineWidth: 10,
              percent: score.clamp(0.0, 1.0),
              animation: false,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: _ringColor,
              backgroundColor: AppColors.border,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppFormatters.percentage(score),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: _ringColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Threat Level',
                    style: AppTextStyles.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _ringColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
            ),
            child: Text(
              _label,
              style: AppTextStyles.labelLarge.copyWith(
                color: _ringColor,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
