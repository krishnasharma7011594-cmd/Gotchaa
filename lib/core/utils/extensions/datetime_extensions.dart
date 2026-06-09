/// DateTime extension utilities.
///
/// Provides convenient methods for common DateTime operations.
library;

/// Extensions on DateTime class.
extension DateTimeExtensions on DateTime {
  /// Check if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if this date is tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get a user-friendly date string.
  ///
  /// Returns "Today", "Yesterday", "Tomorrow", or formatted date.
  String get friendlyDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return '$day/$month/$year';
  }

  /// Get a user-friendly date and time string.
  String get friendlyDateTime {
    if (isToday) {
      return 'Today at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    return '$friendlyDate ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Get the time since this datetime as a human-readable string.
  ///
  /// Example: "5 minutes ago", "2 hours ago", "3 days ago"
  String get agoString {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  /// Get the beginning of the day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get the end of the day (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get the beginning of the week (Monday).
  DateTime get startOfWeek {
    final days = weekday - 1; // Monday is 1, so subtract 1
    return subtract(Duration(days: days)).startOfDay;
  }

  /// Get the end of the week (Sunday).
  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6)).endOfDay;

  /// Get the beginning of the month.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get the end of the month.
  DateTime get endOfMonth =>
      DateTime(year, month + 1).subtract(const Duration(days: 1)).endOfDay;

  /// Get the beginning of the year.
  DateTime get startOfYear => DateTime(year, 1, 1);

  /// Get the end of the year.
  DateTime get endOfYear =>
      DateTime(year + 1, 1, 1).subtract(const Duration(seconds: 1));

  /// Check if this datetime is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Check if this datetime is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Get the age in years.
  int get ageInYears {
    final now = DateTime.now();
    int years = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      years--;
    }
    return years;
  }

  /// Format the datetime using a custom pattern.
  ///
  /// Example patterns: 'yyyy-MM-dd', 'HH:mm:ss', 'dd/MM/yyyy HH:mm'
  String format(String pattern) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String result = pattern;
    result = result.replaceAll('yyyy', year.toString());
    result = result.replaceAll('yy', year.toString().substring(2));
    result = result.replaceAll(
      'MMMM',
      'January February March April May June July August September October November December'
          .split(' ')[month - 1],
    );
    result = result.replaceAll('MMM', months[month - 1]);
    result = result.replaceAll('MM', month.toString().padLeft(2, '0'));
    result = result.replaceAll('M', month.toString());
    result = result.replaceAll('dd', day.toString().padLeft(2, '0'));
    result = result.replaceAll('d', day.toString());
    result = result.replaceAll(
      'EEEE',
      'Monday Tuesday Wednesday Thursday Friday Saturday Sunday'.split(
        ' ',
      )[weekday - 1],
    );
    result = result.replaceAll('EEE', days[weekday - 1]);
    result = result.replaceAll('HH', hour.toString().padLeft(2, '0'));
    result = result.replaceAll('H', hour.toString());
    result = result.replaceAll('hh', (hour % 12).toString().padLeft(2, '0'));
    result = result.replaceAll('h', (hour % 12).toString());
    result = result.replaceAll('mm', minute.toString().padLeft(2, '0'));
    result = result.replaceAll('m', minute.toString());
    result = result.replaceAll('ss', second.toString().padLeft(2, '0'));
    result = result.replaceAll('s', second.toString());

    return result;
  }
}

/// Extensions on Duration class.
extension DurationExtensions on Duration {
  /// Get a user-friendly string representation of the duration.
  String get friendlyString {
    if (inSeconds < 60) {
      return '${inSeconds}s';
    } else if (inMinutes < 60) {
      return '${inMinutes}m';
    } else if (inHours < 24) {
      return '${inHours}h';
    } else {
      return '${inDays}d';
    }
  }

  /// Get a detailed string representation.
  String get detailedString {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'}');
    if (minutes > 0) parts.add('$minutes minute${minutes == 1 ? '' : 's'}');
    if (seconds > 0) parts.add('$seconds second${seconds == 1 ? '' : 's'}');

    return parts.join(', ').isEmpty ? '0 seconds' : parts.join(', ');
  }
}
