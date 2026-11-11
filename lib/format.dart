import 'package:intl/intl.dart';

import 'currency.dart';
import 'settings.dart';

final _fmt2 = NumberFormat('#,##0.##', 'en_US');
final _fmt0 = NumberFormat('#,##0', 'en_US');

/// Сумма в сотых → «$1 250.5», «1 250 000 сум», «¥300».
/// [cur] — код валюты; по умолчанию основная валюта из настроек.
String money(int cents, {String? cur, bool plus = false}) {
  final c = currencyOf(cur ?? AppSettings.I.currency);
  final v = cents.abs() / 100;
  final body = (c.decimals == 0 ? _fmt0.format(v.round()) : _fmt2.format(v)).replaceAll(',', ' ');
  final sym = c.symbol(AppSettings.I.lang);
  final sign = cents < 0 ? '−' : (plus && cents > 0 ? '+' : '');
  return c.prefix ? '$sign$sym$body' : '$sign$body $sym';
}

/// Короткая запись курса: 12 850.4 / 7.15 / 0.0781
String rateStr(double v) {
  if (v >= 100) return _fmt0.format(v.round()).replaceAll(',', ' ');
  if (v >= 1) return NumberFormat('#,##0.##', 'en_US').format(v).replaceAll(',', ' ');
  return NumberFormat('0.####', 'en_US').format(v);
}

String currencySymbol(String code) => currencyOf(code).symbol(AppSettings.I.lang);

/// "1 250,50" / "$1250.5" -> 125050. null если не число.
int? parseMoney(String s) {
  final clean = s.replaceAll(RegExp(r'[\s $]'), '').replaceAll(',', '.');
  if (clean.isEmpty) return null;
  final v = double.tryParse(clean);
  if (v == null) return null;
  return (v * 100).round();
}

/// Сумма в сотых -> текст для поля ввода.
String moneyInput(int cents) {
  if (cents % 100 == 0) return (cents ~/ 100).toString();
  return (cents / 100).toStringAsFixed(2);
}

double? parseNum(String s) {
  final clean = s.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
  if (clean.isEmpty) return null;
  return double.tryParse(clean);
}

String two(int n) => n.toString().padLeft(2, '0');

String dateStr(DateTime d) => '${two(d.day)}.${two(d.month)}.${d.year}';
