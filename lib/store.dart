import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'models.dart';

/// Единое хранилище приложения. Данных у одного пользователя немного,
/// поэтому всё держим в памяти и перечитываем после каждого изменения.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  static const defaultCategories = ['Груз', 'Доставка Китай', 'Машина', 'Таможня', 'Склад', 'Прочее'];

  Database? _db;
  Database get db => _db!;

  List<Client> clients = [];
  List<Order> orders = [];
  List<Payment> payments = [];
  List<Expense> expenses = [];

  Map<int, int> _balances = {};

  Future<void> init() async {
    _db = await AppDatabase.open();
    await reload();
  }

  Future<void> reload() async {
    clients = (await db.query('clients', orderBy: 'name COLLATE NOCASE'))
        .map(Client.fromMap)
        .toList();
    orders = (await db.query('orders', orderBy: 'accepted_at DESC, id DESC'))
        .map(Order.fromMap)
        .toList();
    payments = (await db.query('payments', orderBy: 'paid_at DESC, id DESC'))
        .map(Payment.fromMap)
        .toList();
    expenses = (await db.query('expenses', orderBy: 'spent_at DESC, id DESC'))
        .map(Expense.fromMap)
        .toList();
    _computeBalances();
    notifyListeners();
  }

  void _computeBalances() {
    final b = <int, int>{for (final c in clients) c.id!: 0};
    for (final o in orders) {
      b[o.clientId] = (b[o.clientId] ?? 0) + o.amountCents;
    }
    for (final p in payments) {
      b[p.clientId] = (b[p.clientId] ?? 0) - p.amountCents;
    }
    _balances = b;
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

  /// > 0 — клиент должен, < 0 — аванс (переплата).
  int balanceOf(int clientId) => _balances[clientId] ?? 0;

  int get totalDebt => _balances.values.where((v) => v > 0).fold(0, (a, b) => a + b);
  int get totalAdvance => _balances.values.where((v) => v < 0).fold(0, (a, b) => a - b);

  List<Order> ordersOf(int clientId) => orders.where((o) => o.clientId == clientId).toList();
  List<Payment> paymentsOf(int clientId) => payments.where((p) => p.clientId == clientId).toList();
  int paidForOrder(int orderId) =>
      payments.where((p) => p.orderId == orderId).fold(0, (a, p) => a + p.amountCents);

  List<String> get categories {
    final set = <String>{...defaultCategories};
    for (final e in expenses) {
      set.add(e.category);
    }
    return set.toList();
  }

  MonthSummary summary(YearMonth m) {
    var income = 0, expense = 0, ordSum = 0, ordCount = 0;
    var weight = 0.0;
    final byCat = <String, int>{};
    for (final p in payments) {
      if (m.contains(p.paidAt)) income += p.amountCents;
    }
    for (final e in expenses) {
      if (m.contains(e.spentAt)) {
        expense += e.amountCents;
        byCat[e.category] = (byCat[e.category] ?? 0) + e.amountCents;
      }
    }
    for (final o in orders) {
      if (m.contains(o.acceptedAt)) {
        ordSum += o.amountCents;
        ordCount++;
        weight += o.weightKg ?? 0;
      }
    }
    final sortedCat = Map.fromEntries(
      byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return MonthSummary(
      month: m,
      incomeCents: income,
      expenseCents: expense,
      ordersCents: ordSum,
      ordersCount: ordCount,
      weightKg: weight,
      expensesByCategory: sortedCat,
    );
  }

  /// Все месяцы, в которых есть хоть одна запись, + текущий. От новых к старым.
  List<YearMonth> get months {
    final set = <YearMonth>{YearMonth.now()};
    for (final o in orders) {
      set.add(YearMonth.of(o.acceptedAt));
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

  Future<int> saveClient(Client c) => _save('clients', c.toMap());
  Future<int> saveOrder(Order o) => _save('orders', o.toMap());
  Future<int> savePayment(Payment p) => _save('payments', p.toMap());
  Future<int> saveExpense(Expense e) => _save('expenses', e.toMap());

  Future<void> deleteClient(int id) => _delete('clients', id);
  Future<void> deleteOrder(int id) => _delete('orders', id);
  Future<void> deletePayment(int id) => _delete('payments', id);
  Future<void> deleteExpense(int id) => _delete('expenses', id);

  Future<void> setOrderDone(Order o, bool done) => saveOrder(Order(
        id: o.id,
        clientId: o.clientId,
        description: o.description,
        weightKg: o.weightKg,
        quantity: o.quantity,
        amountCents: o.amountCents,
        acceptedAt: o.acceptedAt,
        doneAt: done ? today() : null,
        note: o.note,
      ));

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
    await reload();
  }
}
