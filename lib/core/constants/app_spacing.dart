import 'package:flutter/material.dart';

/// Consistent spacing and sizing tokens used across the application.
class AppSpacing {
  AppSpacing._();

  // ── Spacing Scale ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // ── Card Radius ──
  static const double cardRadius = 16;
  static const double badgeRadius = 8;

  // ── Edge Insets ──
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);
}
