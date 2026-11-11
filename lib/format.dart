import 'package:intl/intl.dart';

final _moneyFmt = NumberFormat('#,##0.##', 'en_US');

/// 125050 -> "$1 250.5"
String money(int cents, {bool plus = false}) {
  final abs = _moneyFmt.format(cents.abs() / 100).replaceAll(',', ' ');
  final sign = cents < 0 ? '−' : (plus && cents > 0 ? '+' : '');
  return '$sign\$$abs';
}

/// "1 250,50" / "$1250.5" -> 125050. null если не число.
int? parseMoney(String s) {
  final clean = s.replaceAll(RegExp(r'[\s $]'), '').replaceAll(',', '.');
  if (clean.isEmpty) return null;
  final v = double.tryParse(clean);
  if (v == null) return null;
  return (v * 100).round();
}

/// Сумма в центах -> текст для поля ввода.
String moneyInput(int cents) {
  if (cents % 100 == 0) return (cents ~/ 100).toString();
  return (cents / 100).toStringAsFixed(2);
}

double? parseNum(String s) {
  final clean = s.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
  if (clean.isEmpty) return null;
  return double.tryParse(clean);
}

String numInput(double? v) {
  if (v == null) return '';
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

String kg(double v) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  return '$s кг';
}

String two(int n) => n.toString().padLeft(2, '0');

String dateStr(DateTime d) => '${two(d.day)}.${two(d.month)}.${d.year}';
