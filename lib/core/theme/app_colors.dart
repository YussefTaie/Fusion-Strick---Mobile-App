import 'dart:ui';

/// Centralized color palette for the FusionStrick cybersecurity theme.
/// All colors are defined here — never use inline color values.
class AppColors {
  AppColors._();

  // ── Core Surfaces ──
  static const Color background = Color(0xFF0B0F14);
  static const Color card = Color(0xFF111827);
  static const Color border = Color(0xFF1E293B);
  static const Color cardHover = Color(0xFF162032);

  // ── Accent ──
  static const Color primary = Color(0xFF38BDF8);
  static const Color primaryDim = Color(0x3338BDF8); // 20% opacity glow

  // ── Status ──
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFACC15);
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF38BDF8);

  // ── Status Dim (for backgrounds / glows) ──
  static const Color dangerDim = Color(0x33EF4444);
  static const Color warningDim = Color(0x33FACC15);
  static const Color successDim = Color(0x3322C55E);
  static const Color infoDim = Color(0x3338BDF8);

  // ── Text ──
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFFE5EEF8);
  static const Color textMuted = Color(0xFF94A3B8);
}
