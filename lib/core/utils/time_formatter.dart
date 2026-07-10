import 'package:intl/intl.dart';

/// Converts a 24-hour "HH:mm" string to a 12-hour "h:mm a" string.
String format12Hour(String time24) {
  final parts = time24.split(':');
  if (parts.length < 2) return time24;
  int hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';
  if (hour == 0) hour = 12;
  else if (hour > 12) hour -= 12;
  return '$hour:$minute $period';
}

/// Formats a [DateTime] as a chat-list friendly string.
String formatListTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
  return DateFormat('d/M/yy').format(dt);
}

/// Formats a message timestamp for the bubble.
String formatBubbleTime(DateTime dt) => DateFormat('h:mm a').format(dt);

const List<String> kDays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

String get todayName => DateFormat('EEEE').format(DateTime.now());

