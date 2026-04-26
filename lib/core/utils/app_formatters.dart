/// Utility helpers for formatting data across the app.
class AppFormatters {
  AppFormatters._();

  /// Formats a DateTime into a relative time string (e.g. "3m ago").
  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Formats large numbers with K/M suffixes.
  static String compactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Returns percentage string from a 0.0–1.0 double.
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  /// Formats confidence as a percentage string.
  static String confidence(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
