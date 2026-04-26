import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Displays a status label with colored background.
///
/// Use [StatusType] to select the visual variant.
enum StatusType { danger, warning, success, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.showDot = true,
  });

  final String label;
  final StatusType type;
  final bool showDot;

  Color get _color {
    switch (type) {
      case StatusType.danger:
        return AppColors.danger;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.success:
        return AppColors.success;
      case StatusType.info:
        return AppColors.info;
    }
  }

  Color get _bgColor {
    switch (type) {
      case StatusType.danger:
        return AppColors.dangerDim;
      case StatusType.warning:
        return AppColors.warningDim;
      case StatusType.success:
        return AppColors.successDim;
      case StatusType.info:
        return AppColors.infoDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
