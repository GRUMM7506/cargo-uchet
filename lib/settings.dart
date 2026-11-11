import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AccentOption {
  final String name;
  final Color color;
  const AccentOption(this.name, this.color);
}

/// Настройки приложения. Хранятся в таблице settings той же базы,
/// поэтому попадают и в резервную копию.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings I = AppSettings._();

  static const accents = [
    AccentOption('Синий', Color(0xFF2357C6)),
    AccentOption('Изумруд', Color(0xFF0E8A6A)),
    AccentOption('Фиолетовый', Color(0xFF6A4CE0)),
    AccentOption('Янтарь', Color(0xFFD9780F)),
    AccentOption('Малиновый', Color(0xFFC2185B)),
    AccentOption('Графит', Color(0xFF4A5A6A)),
  ];

  static const _defaultHidden = {OrderField.code, OrderField.extra};

  Database? _db;

  ThemeMode themeMode = ThemeMode.system;
  int accentIndex = 0;
  Set<OrderField> hidden = {..._defaultHidden};
  Pricing defaultPricing = Pricing.fixed;
  int? defaultRateKgCents;
  int? defaultRateUnitCents;

  Color get accent => accents[accentIndex.clamp(0, accents.length - 1)].color;

  bool show(OrderField f) => !hidden.contains(f);

  /// Какие способы расчёта доступны с учётом скрытых полей.
  List<Pricing> get availablePricing => [
        Pricing.fixed,
        if (show(OrderField.pricing) && show(OrderField.weight)) Pricing.perKg,
        if (show(OrderField.pricing) && show(OrderField.quantity)) Pricing.perUnit,
      ];

  Pricing get effectiveDefaultPricing =>
      availablePricing.contains(defaultPricing) ? defaultPricing : Pricing.fixed;

  Future<void> load(Database db) async {
    _db = db;
    final rows = await db.query('settings');
    final m = {for (final r in rows) r['key'] as String: r['value'] as String};

    themeMode = switch (m['theme']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    accentIndex = int.tryParse(m['accent'] ?? '') ?? 0;
    if (m.containsKey('hidden_fields')) {
      final keys = m['hidden_fields']!.split(',').where((s) => s.isNotEmpty).toSet();
      hidden = OrderField.values.where((f) => keys.contains(f.key)).toSet();
    } else {
      hidden = {..._defaultHidden};
    }
    defaultPricing = Pricing.fromDb(m['default_pricing']);
    defaultRateKgCents = int.tryParse(m['rate_kg'] ?? '');
    defaultRateUnitCents = int.tryParse(m['rate_unit'] ?? '');
    notifyListeners();
  }

  Future<void> _put(String key, String? value) async {
    final db = _db;
    if (db == null) return;
    if (value == null) {
      await db.delete('settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _put('theme', switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setAccent(int i) async {
    accentIndex = i;
    notifyListeners();
    await _put('accent', '$i');
  }

  Future<void> setFieldVisible(OrderField f, bool visible) async {
    if (visible) {
      hidden.remove(f);
    } else {
      hidden.add(f);
    }
    notifyListeners();
    await _put('hidden_fields', hidden.map((f) => f.key).join(','));
  }

  Future<void> setDefaultPricing(Pricing p) async {
    defaultPricing = p;
    notifyListeners();
    await _put('default_pricing', p.db);
  }

  Future<void> setDefaultRateKg(int? cents) async {
    defaultRateKgCents = cents;
    notifyListeners();
    await _put('rate_kg', cents?.toString());
  }

  Future<void> setDefaultRateUnit(int? cents) async {
    defaultRateUnitCents = cents;
    notifyListeners();
    await _put('rate_unit', cents?.toString());
  }
}
