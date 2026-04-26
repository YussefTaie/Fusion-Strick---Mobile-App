import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// A shimmering skeleton placeholder used during loading states.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  /// Creates a card-shaped skeleton.
  const LoadingSkeleton.card({
    super.key,
    this.width,
    this.height = 120,
    this.borderRadius,
  });

  /// Creates a circular skeleton (e.g. for avatars).
  const LoadingSkeleton.circle({
    super.key,
    this.width = 48,
    this.height = 48,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }
}
