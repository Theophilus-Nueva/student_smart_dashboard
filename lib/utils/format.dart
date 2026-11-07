import 'package:intl/intl.dart';

final _time = DateFormat('h:mm a');
final _dayTime = DateFormat('EEE, d MMM · h:mm a');

String formatTime(DateTime t) => _time.format(t);

/// "Today · 10:15 AM", "Yesterday · 3:02 PM", "Thu, 5 Nov · 3:02 PM".
String formatWhen(DateTime t, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(t);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today · ${_time.format(t)}';
  if (diff == 1) return 'Yesterday · ${_time.format(t)}';
  return _dayTime.format(t);
}

/// "Today", "Yesterday" or "Thu, 5 Nov 2026" (Recent Activity group headings).
String formatDayHeading(DateTime t, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final diff = today.difference(_dateOnly(t)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM yyyy').format(t);
}

String formatLastSync(DateTime? t) => t == null ? 'never' : formatTime(t);

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);
