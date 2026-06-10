// Port dari src/utils/date.js. Format ISO YYYY-MM-DD, jam HH:MM 24h WIB (Asia/Jakarta).

String _isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String getToday() => _isoDate(DateTime.now());

String getTimeWIB() {
  final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
  final hh = wib.hour.toString().padLeft(2, '0');
  final mm = wib.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String getStartOfWeek([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return _isoDate(monday);
}

String getEndOfWeek([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  final sunday = d.add(Duration(days: 7 - d.weekday));
  return _isoDate(sunday);
}

String getStartOfMonth([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  return _isoDate(DateTime(d.year, d.month, 1));
}

String getEndOfMonth([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  return _isoDate(DateTime(d.year, d.month + 1, 0));
}

String getStartOfYear([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  return _isoDate(DateTime(d.year, 1, 1));
}

String getEndOfYear([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  return _isoDate(DateTime(d.year, 12, 31));
}

({String start, String end}) getLastWeekRange() {
  final startThis = DateTime.parse(getStartOfWeek());
  final startPrev = startThis.subtract(const Duration(days: 7));
  final endPrev = startThis.subtract(const Duration(days: 1));
  return (start: _isoDate(startPrev), end: _isoDate(endPrev));
}

({String start, String end}) getLastMonthRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 1, 1);
  final end = DateTime(now.year, now.month, 0);
  return (start: _isoDate(start), end: _isoDate(end));
}

({String start, String end}) getLastYearRange() {
  final y = DateTime.now().year - 1;
  return (start: '$y-01-01', end: '$y-12-31');
}

({String start, String end}) getPreviousRangeOfSameLength(String start, String end) {
  final s = DateTime.parse(start);
  final e = DateTime.parse(end);
  final days = e.difference(s).inDays;
  final prevEnd = s.subtract(const Duration(days: 1));
  final prevStart = prevEnd.subtract(Duration(days: days));
  return (start: _isoDate(prevStart), end: _isoDate(prevEnd));
}

int daysBetween(String start, String end) =>
    DateTime.parse(end).difference(DateTime.parse(start)).inDays;

String formatRangeShort(String start, String end) {
  String fmt(String s) {
    final d = DateTime.parse(s);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }
  if (start == end) return fmt(start);
  return '${fmt(start)} - ${fmt(end)}';
}

DateTime parseDate(String iso) {
  final parts = iso.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}
