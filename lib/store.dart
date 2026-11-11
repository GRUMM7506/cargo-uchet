import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'l10n.dart';
import 'models.dart';
import 'services/photos.dart';
import 'services/rates.dart';
import 'settings.dart';

/// Единое хранилище приложения. Данных у одного пользователя немного,
/// поэтому всё держим в памяти и перечитываем после каждого изменения.
///
/// Долг клиента = сумма цен его заказов − залоги − оплаты.
/// Долги ведутся по валютам («корзины»): заказ в $ — долг в $; оплата в сумах
/// в счёт долларового долга пересчитывается по курсу на день оплаты.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  Database? _db;
  Database get db => _db!;

  List<Client> clients = [];
  List<Order> orders = [];
  List<Payment> payments = [];
  List<Expense> expenses = [];

  Map<int, Map<String, int>> _buckets = {};
  Map<int, int> _paidByOrder = {};

  String get main => AppSettings.I.currency;

  Future<void> init() async {
    await Photos.init();
    _db = await AppDatabase.open();
    await AppSettings.I.load(db);
    Fx.I.onChanged = notifyListeners;
    await Fx.I.load(db);
    await reload();
    await Photos.cleanup(_usedPhotos());
  }

  Set<String> _usedPhotos() => {
        for (final c in clients)
          if (c.photo != null) c.photo!,
        for (final o in orders)
          if (o.photo != null) o.photo!,
      };

  Future<void> reload() async {
    clients = (await db.query('clients', orderBy: 'name COLLATE NOCASE')).map(Client.fromMap).toList();
    orders = (await db.query('orders', orderBy: 'accepted_at DESC, id DESC')).map(Order.fromMap).toList();
    payments = (await db.query('payments', orderBy: 'paid_at DESC, id DESC')).map(Payment.fromMap).toList();
    expenses = (await db.query('expenses', orderBy: 'spent_at DESC, id DESC')).map(Expense.fromMap).toList();
    _compute();
    notifyListeners();
  }

  void _compute() {
    final b = <int, Map<String, int>>{for (final c in clients) c.id!: {}};
    final paid = <int, int>{};
    final orderCur = {for (final o in orders) o.id!: o.currency};
    void add(int client, String cur, int v) {
      final m = b.putIfAbsent(client, () => {});
      m[cur] = (m[cur] ?? 0) + v;
    }

    for (final o in orders) {
      add(o.clientId, o.currency, o.priceCents - o.depositCents);
    }
    for (final p in payments) {
      add(p.clientId, p.appliedCurrency, -p.appliedCents);
      if (p.orderId != null) {
        final oc = orderCur[p.orderId!];
        if (oc != null) {
          final v = p.appliedCurrency == oc ? p.appliedCents : Fx.I.convert(p.amountCents, p.currency, oc, p.paidAt);
          paid[p.orderId!] = (paid[p.orderId!] ?? 0) + v;
        }
      }
    }
    _buckets = b;
    _paidByOrder = paid;
  }

  // ---------- Запросы ----------

  Client? clientById(int id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  String clientName(int id) => clientById(id)?.name ?? '—';

  Order? orderById(int id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Долг клиента по валютам (только ненулевые). > 0 — должен, < 0 — переплата.
  Map<String, int> bucketsOf(int clientId) =>
      Map.fromEntries((_buckets[clientId] ?? const {}).entries.where((e) => e.value != 0));

  /// Итог долга клиента в валюте [cur] (по умолчанию основная) по сегодняшнему курсу.
  int balanceOf(int clientId, [String? cur]) {
    final to = cur ?? main;
    var sum = 0;
    for (final e in (_buckets[clientId] ?? const <String, int>{}).entries) {
      sum += Fx.I.convert(e.value, e.key, to);
    }
    return sum;
  }

  /// Валюта, в которой у клиента больше всего долга (для оплат без заказа).
  String? debtCurrencyOf(int clientId) {
    String? best;
    var bestV = 0;
    for (final e in (_buckets[clientId] ?? const <String, int>{}).entries) {
      if (e.value <= 0) continue;
      final v = Fx.I.convert(e.value, e.key, 'USD');
      if (v > bestV) {
        bestV = v;
        best = e.key;
      }
    }
    return best;
  }

  int get totalDebt => clients.map((c) => balanceOf(c.id!)).where((v) => v > 0).fold(0, (a, b) => a + b);
  int get totalOverpaid => clients.map((c) => balanceOf(c.id!)).where((v) => v < 0).fold(0, (a, b) => a - b);

  /// Должники, от большего долга к меньшему.
  List<Client> get debtors {
    final bal = {for (final c in clients) c.id!: balanceOf(c.id!)};
    return clients.where((c) => bal[c.id!]! > 0).toList()..sort((a, b) => bal[b.id!]!.compareTo(bal[a.id!]!));
  }

  /// Оплачено по заказу отдельными оплатами (без залога), в валюте заказа.
  int paidForOrder(int orderId) => _paidByOrder[orderId] ?? 0;

  /// Сколько ещё должны за конкретный заказ, в валюте заказа (не меньше нуля).
  int remainingOf(Order o) {
    final r = o.priceCents - o.depositCents - paidForOrder(o.id!);
    return r < 0 ? 0 : r;
  }

  List<Order> ordersOf(int clientId) => orders.where((o) => o.clientId == clientId).toList();
  List<Payment> paymentsOf(int clientId) => payments.where((p) => p.clientId == clientId).toList();
  List<Payment> paymentsForOrder(int orderId) => payments.where((p) => p.orderId == orderId).toList();

  List<String> get categories {
    final set = <String>{...t.defaultCategories};
    for (final e in expenses) {
      set.add(e.category);
    }
    return set.toList();
  }

  /// Итоги месяца в валюте [cur] (по умолчанию основная); каждая запись — по курсу своего дня.
  MonthSummary summary(YearMonth m, [String? cur]) {
    final to = cur ?? main;
    final fx = Fx.I;
    var pays = 0, deps = 0, expense = 0, ordSum = 0, ordCount = 0;
    final byCat = <String, int>{};
    for (final p in payments) {
      if (m.contains(p.paidAt)) pays += fx.convert(p.amountCents, p.currency, to, p.paidAt);
    }
    for (final o in orders) {
      if (o.depositCents > 0 && m.contains(o.depositDate)) {
        deps += fx.convert(o.depositCents, o.currency, to, o.depositDate);
      }
      if (m.contains(o.acceptedAt)) {
        ordSum += fx.convert(o.priceCents, o.currency, to, o.acceptedAt);
        ordCount++;
      }
    }
    for (final e in expenses) {
      if (m.contains(e.spentAt)) {
        final v = fx.convert(e.amountCents, e.currency, to, e.spentAt);
        expense += v;
        byCat[e.category] = (byCat[e.category] ?? 0) + v;
      }
    }
    final sortedCat = Map.fromEntries(byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return MonthSummary(
      month: m,
      paymentsCents: pays,
      depositsCents: deps,
      expenseCents: expense,
      ordersCents: ordSum,
      ordersCount: ordCount,
      expensesByCategory: sortedCat,
    );
  }

  /// Все месяцы, в которых есть хоть одна запись, + текущий. От новых к старым.
  List<YearMonth> get months {
    final set = <YearMonth>{YearMonth.now()};
    for (final o in orders) {
      set.add(YearMonth.of(o.acceptedAt));
      if (o.depositCents > 0) set.add(YearMonth.of(o.depositDate));
    }
    for (final p in payments) {
      set.add(YearMonth.of(p.paidAt));
    }
    for (final e in expenses) {
      set.add(YearMonth.of(e.spentAt));
    }
    return set.toList()..sort((a, b) => b.compareTo(a));
  }

  // ---------- Изменения ----------

  Future<int> _save(String table, Map<String, Object?> map) async {
    final id = map['id'] as int?;
    int result;
    if (id == null) {
      result = await db.insert(table, map..remove('id'));
    } else {
      await db.update(table, map, where: 'id = ?', whereArgs: [id]);
      result = id;
    }
    await reload();
    return result;
  }

  Future<void> _delete(String table, int id) async {
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
    await reload();
  }

  /// Сохраняет клиента; если фото сменилось — удаляет старый файл.
  Future<int> saveClient(Client c) async {
    final old = c.id == null ? null : clientById(c.id!)?.photo;
    final id = await _save('clients', c.toMap());
    if (old != null && old != c.photo) await Photos.delete(old);
    return id;
  }

  Future<int> saveOrder(Order o) async {
    final prev = o.id == null ? null : orderById(o.id!);
    final old = prev?.photo;
    final id = await _save('orders', o.toMap());
    if (old != null && old != o.photo) await Photos.delete(old);
    // валюта заказа сменилась — пересчитываем привязанные оплаты
    if (prev != null && prev.currency != o.currency) {
      for (final p in paymentsForOrder(id)) {
        final applied = p.withApplied(o.currency, Fx.I.convert(p.amountCents, p.currency, o.currency, p.paidAt));
        await db.update('payments', applied.toMap(), where: 'id = ?', whereArgs: [p.id]);
      }
      await reload();
    }
    return id;
  }

  /// Валюта, в счёт которой пойдёт оплата: валюта заказа или основного долга клиента.
  String applyCurrencyFor(Payment p) {
    if (p.id != null && p.orderId == null) {
      for (final old in payments) {
        if (old.id == p.id && old.orderId == null && old.clientId == p.clientId) return old.appliedCurrency;
      }
    }
    if (p.orderId != null) {
      final o = orderById(p.orderId!);
      if (o != null) return o.currency;
    }
    return debtCurrencyOf(p.clientId) ?? p.currency;
  }

  Future<int> savePayment(Payment p) {
    final cur = applyCurrencyFor(p);
    final applied = p.withApplied(cur, Fx.I.convert(p.amountCents, p.currency, cur, p.paidAt));
    return _save('payments', applied.toMap());
  }
  Future<int> saveExpense(Expense e) => _save('expenses', e.toMap());

  Future<void> deleteClient(int id) async {
    final photos = [clientById(id)?.photo, for (final o in ordersOf(id)) o.photo];
    await _delete('clients', id);
    for (final p in photos) {
      await Photos.delete(p);
    }
  }

  Future<void> deleteOrder(int id) async {
    final photo = orderById(id)?.photo;
    await _delete('orders', id);
    await Photos.delete(photo);
  }

  Future<void> deletePayment(int id) => _delete('payments', id);
  Future<void> deleteExpense(int id) => _delete('expenses', id);

  Future<void> setOrderDone(Order o, bool done) =>
      saveOrder(done ? o.copyWith(doneAt: today()) : o.copyWith(clearDone: true));

  // ---------- Резервная копия ----------

  Future<String> dbPath() => AppDatabase.path();

  /// Заменяет текущую базу файлом [sourcePath] и перечитывает данные.
  Future<void> replaceDatabase(String sourcePath) async {
    final target = await AppDatabase.path();
    await _db?.close();
    _db = null;
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('$target$suffix');
      if (await f.exists()) await f.delete();
    }
    await File(sourcePath).copy(target);
    _db = await AppDatabase.open();
    await AppSettings.I.load(db);
    await Fx.I.load(db);
    await reload();
  }
}
