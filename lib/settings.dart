import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'currency.dart';
import 'models.dart';

/// Настройки приложения. Хранятся в таблице settings той же базы,
/// поэтому попадают и в резервную копию.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings I = AppSettings._();

  static const accents = [
    Color(0xFF2357C6), // синий
    Color(0xFF0E8A6A), // изумруд
    Color(0xFF6A4CE0), // фиолетовый
    Color(0xFFD9780F), // янтарь
    Color(0xFFC2185B), // малиновый
    Color(0xFF4A5A6A), // графит
  ];

  static const languages = {'ru': 'Русский', 'uz': 'Oʻzbekcha'};

  Database? _db;

  String lang = 'ru';
  ThemeMode themeMode = ThemeMode.system;
  int accentIndex = 0;
  Set<OrderField> hidden = {};

  /// Обучение: вступление показано, карточка «С чего начать» скрыта, копия сделана.
  bool introDone = false;
  bool checklistHidden = false;
  bool backupDone = false;

  /// Размер интерфейса: 'auto' | 'small' | 'normal' | 'large'.
  String uiScale = 'auto';

  /// Множитель масштаба для экрана шириной [width] (логических точек).
  double scaleFor(double width) {
    // «Авто»: на узких экранах и при увеличенном масштабе телефона чуть уменьшаем всё.
    final auto = (width / 392).clamp(0.82, 1.0);
    return switch (uiScale) {
      'small' => auto * 0.9,
      'normal' => 1.0,
      'large' => 1.1,
      _ => auto,
    };
  }

  /// Основная валюта: в ней итоги, долги и отчёты; её предлагаем при вводе.
  String currency = 'USD';

  /// Валюты, которые показываются при выборе.
  List<String> enabledCurrencies = [...defaultEnabledCurrencies];

  /// Валюты для выбора: включённые + [extra] (валюта редактируемой записи).
  List<String> currencyChoices([String? extra]) => [
        ...currencies.map((c) => c.code).where((c) => enabledCurrencies.contains(c) || c == extra || c == currency),
      ];

  Color get accent => accents[accentIndex.clamp(0, accents.length - 1)];

  bool show(OrderField f) => !hidden.contains(f);

  Future<void> load(Database db) async {
    _db = db;
    final rows = await db.query('settings');
    final m = {for (final r in rows) r['key'] as String: r['value'] as String};

    final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    lang = languages.containsKey(m['lang']) ? m['lang']! : (sys == 'uz' ? 'uz' : 'ru');
    themeMode = switch (m['theme']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    accentIndex = int.tryParse(m['accent'] ?? '') ?? 0;
    final keys = (m['hidden_v3'] ?? '').split(',').where((s) => s.isNotEmpty).toSet();
    hidden = OrderField.values.where((f) => keys.contains(f.name)).toSet();
    introDone = m['intro_done'] == '1';
    checklistHidden = m['checklist_hidden'] == '1';
    backupDone = m['backup_done'] == '1';
    uiScale = const {'auto', 'small', 'normal', 'large'}.contains(m['ui_scale']) ? m['ui_scale']! : 'auto';
    currency = isKnownCurrency(m['currency'] ?? '') ? m['currency']! : 'USD';
    final en = (m['currencies'] ?? '').split(',').where(isKnownCurrency).toList();
    enabledCurrencies = en.isEmpty ? [...defaultEnabledCurrencies] : en;
    notifyListeners();
  }

  Future<void> _put(String key, String value) async {
    await _db?.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setLang(String l) async {
    lang = l;
    notifyListeners();
    await _put('lang', l);
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

  Future<void> setIntroDone(bool v) async {
    introDone = v;
    notifyListeners();
    await _put('intro_done', v ? '1' : '0');
  }

  Future<void> setChecklistHidden(bool v) async {
    checklistHidden = v;
    notifyListeners();
    await _put('checklist_hidden', v ? '1' : '0');
  }

  Future<void> markBackupDone() async {
    if (backupDone) return;
    backupDone = true;
    notifyListeners();
    await _put('backup_done', '1');
  }

  Future<void> setUiScale(String v) async {
    uiScale = v;
    notifyListeners();
    await _put('ui_scale', v);
  }

  Future<void> setCurrency(String code) async {
    currency = code;
    if (!enabledCurrencies.contains(code)) enabledCurrencies = [...enabledCurrencies, code];
    notifyListeners();
    await _put('currency', code);
    await _put('currencies', enabledCurrencies.join(','));
  }

  Future<void> setCurrencyEnabled(String code, bool on) async {
    if (code == currency && !on) return; // основную валюту не выключаем
    enabledCurrencies = on
        ? [...enabledCurrencies.where((c) => c != code), code]
        : enabledCurrencies.where((c) => c != code).toList();
    notifyListeners();
    await _put('currencies', enabledCurrencies.join(','));
  }

  Future<void> setFieldVisible(OrderField f, bool visible) async {
    if (visible) {
      hidden.remove(f);
    } else {
      hidden.add(f);
    }
    notifyListeners();
    await _put('hidden_v3', hidden.map((f) => f.name).join(','));
  }
}
