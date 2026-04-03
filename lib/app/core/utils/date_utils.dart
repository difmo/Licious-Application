import 'package:intl/intl.dart';
import '../../../core/utils/logger.dart';

class AppDateUtils {
  /// Returns whether the current time is past the shop's cut-off (10:00 PM / 22:00)
  /// for tomorrow's delivery.
  static bool isPastCutOff() {
    final now = DateTime.now();
    final cutoffTime = 20; // 8:00 PM
    final isPast = now.hour >= cutoffTime;
    AppLogger.d('AppDateUtils: isPastCutOff check at ${now.hour}:${now.minute} -> $isPast (Cutoff: $cutoffTime:00)');
    return isPast;
  }

  /// Returns the first allowed date for a vacation/pause based on the 8 PM rule.
  static DateTime getFirstAllowedDate() {
    final now = DateTime.now();
    if (isPastCutOff()) {
      return DateTime(now.year, now.month, now.day + 2);
    } else {
      return DateTime(now.year, now.month, now.day + 1);
    }
  }

  /// Formats a DateTime to YYYY-MM-DD
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Generates a list of YYYY-MM-DD strings between [start] and [end] inclusive.
  static List<String> getDatesBetween(DateTime start, DateTime end) {
    List<String> dates = [];
    DateTime current = DateTime(start.year, start.month, start.day);
    DateTime last = DateTime(end.year, end.month, end.day);

    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      dates.add(formatDate(current));
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Checks if two dates are the same day (ignoring time).
  static bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
