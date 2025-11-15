import 'dart:io';

import 'package:intl/intl.dart';

String timeFormated(String? time) {
  final DateTime now =
      time == null ? DateTime.now().toLocal() : DateTime.parse(time).toLocal();
  final DateFormat formatter =
      DateFormat('yyyy-MM-dd HH:mm:ss', Platform.localeName);
  return formatter.format(now);
}

/// 格式化时间
String duTimeLineFormat(DateTime dt) {
  var now = DateTime.now();
  var difference = now.difference(dt);
  if (difference.inSeconds < 60) {
    if (difference.inSeconds < 0) {
      return "0s ago";
    }
    return "${difference.inSeconds}s ago";
  }
  if (difference.inMinutes < 60) {
    return "${difference.inMinutes}m ago";
  }
  // 1天内
  if (difference.inHours < 12) {
    return "${difference.inHours}h ago";
  }
  if (difference.inDays < 3) {
    final dtFormat = new DateFormat('MM-dd hh:mm', Platform.localeName);
    return dtFormat.format(dt);
  }
  // 30天内
  if (difference.inDays < 30) {
    final dtFormat = new DateFormat('yy-MM-dd hh:mm', Platform.localeName);
    return dtFormat.format(dt);
  }
  // MM-dd
  else if (difference.inDays < 365) {
    final dtFormat = new DateFormat('yy-MM-dd', Platform.localeName);
    return dtFormat.format(dt);
  }
  // yyyy-MM-dd
  else {
    final dtFormat = new DateFormat('yyyy-MM-dd', Platform.localeName);
    var str = dtFormat.format(dt);
    return str;
  }
}

/// Format timestamp for message separators (Telegram-style)
/// Returns: "Today 14:30", "Yesterday 09:15", "Monday 16:45", "Jan 15 12:00", "Jan 15, 2024"
String formatDateSeparator(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(Duration(days: 1));
  final messageDate = DateTime(dt.year, dt.month, dt.day);
  final difference = today.difference(messageDate).inDays;

  final timeFormat = DateFormat('HH:mm', Platform.localeName);
  final timeStr = timeFormat.format(dt);

  // Today
  if (messageDate == today) {
    return "Today $timeStr";
  }

  // Yesterday
  if (messageDate == yesterday) {
    return "Yesterday $timeStr";
  }

  // Within last 7 days - show weekday
  if (difference < 7) {
    final weekdayFormat =
        DateFormat('EEEE', Platform.localeName); // Monday, Tuesday, etc.
    return "${weekdayFormat.format(dt)} $timeStr";
  }

  // Within same year - show month and day
  if (dt.year == now.year) {
    final dateFormat = DateFormat('MMM d', Platform.localeName); // Jan 15
    return "${dateFormat.format(dt)} $timeStr";
  }

  // Different year - show full date
  final fullDateFormat =
      DateFormat('MMM d, yyyy', Platform.localeName); // Jan 15, 2024
  return fullDateFormat.format(dt);
}
