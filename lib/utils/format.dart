import 'package:intl/intl.dart';

final NumberFormat _rpFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatRp(num? n) => _rpFormatter.format(n ?? 0);

String displayRp(num? value, {bool hidden = false}) {
  if (hidden) return 'Rp ••••••••';
  return formatRp(value);
}

String formatCompact(num? n) {
  final v = (n ?? 0).toDouble();
  final abs = v.abs();
  if (abs >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)} M';
  if (abs >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(0)} rb';
  return v.toStringAsFixed(0);
}

double pctChange(num current, num previous) {
  if (previous == 0) return current != 0 ? 100 : 0;
  return ((current - previous) / previous.abs()) * 100;
}
