import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../currency.dart';
import '../models.dart';

/// Курсы валют: сколько единиц валюты за 1 доллар, по дням.
/// История хранится в таблице rates, поэтому старые записи
/// пересчитываются по курсу своего дня.
class Fx extends ChangeNotifier {
  Fx._();
  static final Fx I = Fx._();

  Database? _db;

  /// дата 'yyyy-MM-dd' → (код → курс за 1 USD)
  final Map<String, Map<String, double>> _history = {};
  final Map<String, Set<String>> _manual = {}; // дата → коды, введённые вручную
  List<String> _dates = [];

  DateTime? lastUpdate;
  bool updating = false;

  /// Вызывается после изменения курсов (стор подписывается, чтобы перерисовать экраны).
  VoidCallback? onChanged;

  Future<void> load(Database db) async {
    _db = db;
    _history.clear();
    _manual.clear();
    final rows = await db.query('rates');
    for (final r in rows) {
      final d = r['date'] as String;
      final code = r['code'] as String;
      _history.putIfAbsent(d, () => {})[code] = (r['per_usd'] as num).toDouble();
      if ((r['manual'] as int? ?? 0) == 1) _manual.putIfAbsent(d, () => {}).add(code);
    }
    _dates = _history.keys.toList()..sort();
    final meta = await db.query('settings', where: 'key = ?', whereArgs: ['rates_updated']);
    lastUpdate = meta.isEmpty ? null : DateTime.tryParse(meta.first['value'] as String);
    _changed();
  }

  void _changed() {
    notifyListeners();
    onChanged?.call();
  }

  /// Курс валюты к доллару на дату (последний известный не позже даты).
  double perUsd(String code, [DateTime? date]) {
    if (code == 'USD') return 1;
    final key = dateToDb(date ?? today());
    // ищем последнюю дату <= key, у которой есть этот код
    for (var i = _upperIndex(key); i >= 0; i--) {
      final v = _history[_dates[i]]![code];
      if (v != null && v > 0) return v;
    }
    // если раньше ничего нет — первый известный курс после даты
    for (final d in _dates) {
      final v = _history[d]![code];
      if (v != null && v > 0) return v;
    }
    return currencyOf(code).fallbackPerUsd;
  }

  int _upperIndex(String key) {
    var lo = 0, hi = _dates.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_dates[mid].compareTo(key) <= 0) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  /// Перевести сумму (в сотых) из одной валюты в другую по курсу на дату.
  int convert(int cents, String from, String to, [DateTime? date]) {
    if (from == to || cents == 0) return cents;
    return (cents / perUsd(from, date) * perUsd(to, date)).round();
  }

  /// Сколько [to] за 1 [from] сегодня.
  double cross(String from, String to) => perUsd(to) / perUsd(from);

  bool isApprox(String code) => code != 'USD' && !_history.values.any((m) => m.containsKey(code));

  bool isManualToday(String code) => _manual[dateToDb(today())]?.contains(code) ?? false;

  bool get updatedToday => lastUpdate != null && dateToDb(lastUpdate!) == dateToDb(today());

  Future<void> _save(String code, double perUsd, {bool manual = false}) async {
    final d = dateToDb(today());
    await _db?.insert(
      'rates',
      {'date': d, 'code': code, 'per_usd': perUsd, 'manual': manual ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _history.putIfAbsent(d, () => {})[code] = perUsd;
    if (manual) {
      _manual.putIfAbsent(d, () => {}).add(code);
    } else {
      _manual[d]?.remove(code);
    }
    if (!_dates.contains(d)) _dates = [..._dates, d]..sort();
  }

  /// Ручной курс на сегодня.
  Future<void> setManual(String code, double perUsd) async {
    await _save(code, perUsd, manual: true);
    _changed();
  }

  /// Загрузить курсы из интернета. Возвращает true при успехе.
  Future<bool> update() async {
    if (updating) return false;
    updating = true;
    notifyListeners();
    try {
      final rates = await _fetchErApi() ?? await _fetchJsDelivr();
      if (rates == null) return false;
      final todayKey = dateToDb(today());
      for (final c in currencies) {
        if (c.code == 'USD') continue;
        final v = rates[c.code];
        if (v == null || v <= 0) continue;
        if (_manual[todayKey]?.contains(c.code) ?? false) continue; // ручной курс не трогаем
        await _save(c.code, v);
      }
      lastUpdate = DateTime.now();
      await _db?.insert('settings', {'key': 'rates_updated', 'value': lastUpdate!.toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (_) {
      return false;
    } finally {
      updating = false;
      _changed();
    }
  }

  /// Обновить раз в день, без ошибок наружу.
  Future<void> autoUpdate() async {
    if (updatedToday) return;
    await update();
  }

  static Future<Map<String, dynamic>> _getJson(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  /// ExchangeRate-API (open access): {"result":"success","rates":{"UZS":12850.1,...}}
  static Future<Map<String, double>?> _fetchErApi() async {
    try {
      final j = await _getJson('https://open.er-api.com/v6/latest/USD');
      if (j['result'] != 'success') return null;
      final r = j['rates'] as Map<String, dynamic>;
      return {for (final e in r.entries) e.key.toUpperCase(): (e.value as num).toDouble()};
    } catch (_) {
      return null;
    }
  }

  /// Запасной источник: {"date":"…","usd":{"uzs":12850.1,...}}
  static Future<Map<String, double>?> _fetchJsDelivr() async {
    try {
      final j = await _getJson('https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json');
      final r = j['usd'] as Map<String, dynamic>;
      return {for (final e in r.entries) e.key.toUpperCase(): (e.value as num).toDouble()};
    } catch (_) {
      return null;
    }
  }
}
