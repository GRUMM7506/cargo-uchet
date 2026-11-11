import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'l10n.dart';
import 'models.dart';
import 'services/photos.dart';
import 'settings.dart';

/// Единое хранилище приложения. Данных у одного пользователя немного,
/// поэтому всё держим в памяти и перечитываем после каждого изменения.
///
/// Долг клиента = сумма цен его заказов − залоги − оплаты.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  Database? _db;
  Database get db => _db!;

  List<Client> clients = [];
  List<Order> orders = [];
  List<Payment> payments = [];
  List<Expense> expenses = [];

  Map<int, int> _balances = {};
  Map<int, int> _paidByOrder = {};

  Future<void> init() async {
    await Photos.init();
    _db = await AppDatabase.open();
    await AppSettings.I.load(db);
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
    final b = <int, int>{for (final c in clients) c.id!: 0};
    final paid = <int, int>{};
    for (final o in orders) {
      b[o.clientId] = (b[o.clientId] ?? 0) + o.priceCents - o.depositCents;
    }
    for (final p in payments) {
      b[p.clientId] = (b[p.clientId] ?? 0) - p.amountCents;
      if (p.orderId != null) paid[p.orderId!] = (paid[p.orderId!] ?? 0) + p.amountCents;
    }
    _balances = b;
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

  /// > 0 — клиент должен, < 0 — переплата.
  int balanceOf(int clientId) => _balances[clientId] ?? 0;

  int get totalDebt => _balances.values.where((v) => v > 0).fold(0, (a, b) => a + b);
  int get totalOverpaid => _balances.values.where((v) => v < 0).fold(0, (a, b) => a - b);

  /// Должники, от большего долга к меньшему.
  List<Client> get debtors => clients.where((c) => balanceOf(c.id!) > 0).toList()
    ..sort((a, b) => balanceOf(b.id!).compareTo(balanceOf(a.id!)));

  /// Оплачено по заказу отдельными оплатами (без залога).
  int paidForOrder(int orderId) => _paidByOrder[orderId] ?? 0;

  /// Сколько ещё должны за конкретный заказ (не меньше нуля).
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

  MonthSummary summary(YearMonth m) {
    var pays = 0, deps = 0, expense = 0, ordSum = 0, ordCount = 0;
    final byCat = <String, int>{};
    for (final p in payments) {
      if (m.contains(p.paidAt)) pays += p.amountCents;
    }
    for (final o in orders) {
      if (o.depositCents > 0 && m.contains(o.depositDate)) deps += o.depositCents;
      if (m.contains(o.acceptedAt)) {
        ordSum += o.priceCents;
        ordCount++;
      }
    }
    for (final e in expenses) {
      if (m.contains(e.spentAt)) {
        expense += e.amountCents;
        byCat[e.category] = (byCat[e.category] ?? 0) + e.amountCents;
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
    final old = o.id == null ? null : orderById(o.id!)?.photo;
    final id = await _save('orders', o.toMap());
    if (old != null && old != o.photo) await Photos.delete(old);
    return id;
  }

  Future<int> savePayment(Payment p) => _save('payments', p.toMap());
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
    await reload();
  }
}
