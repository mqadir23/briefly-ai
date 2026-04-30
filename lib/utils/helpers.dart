// lib/utils/helpers.dart
import 'package:intl/intl.dart';

class AppHelpers {
  /// Formats a DateTime into a human-readable "Time Ago" string.
  static String getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Extracts the domain from a URL (e.g. "https://edition.cnn.com/..." -> "cnn.com").
  static String getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  /// Capitalizes the first letter of a string.
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Formats a percent for display (0.85 -> "85%").
  static String formatPercent(double val) {
    return '${(val * 100).toInt()}%';
  }
}
