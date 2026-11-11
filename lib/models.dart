// Модели данных. Все суммы хранятся в центах (int), чтобы не было ошибок округления.

import 'l10n.dart';

String dateToDb(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateFromDb(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime? dateFromDbOrNull(Object? s) => s == null ? null : dateFromDb(s as String);

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Поля заказа, которые можно скрыть в настройках.
enum OrderField { photo, description, deposit, due, done, note }

class Client {
  final int? id;
  final String name;
  final String phone;
  final String note;
  final String? photo; // имя файла в папке photos

  const Client({this.id, required this.name, this.phone = '', this.note = '', this.photo});

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'note': note,
        'photo': photo,
      };

  factory Client.fromMap(Map<String, Object?> m) => Client(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        photo: m['photo'] as String?,
      );
}

class Order {
  final int? id;
  final int clientId;
  final String description;
  final String? photo;
  final int priceCents;
  final int depositCents;
  final DateTime? depositAt;
  final DateTime acceptedAt;
  final DateTime? dueAt;
  final DateTime? doneAt;
  final String note;

  const Order({
    this.id,
    required this.clientId,
    this.description = '',
    this.photo,
    required this.priceCents,
    this.depositCents = 0,
    this.depositAt,
    required this.acceptedAt,
    this.dueAt,
    this.doneAt,
    this.note = '',
  });

  bool get isDone => doneAt != null;

  /// Дата, которой учитывается залог (по умолчанию — дата приёма).
  DateTime get depositDate => depositAt ?? acceptedAt;

  bool get isOverdue => !isDone && dueAt != null && dueAt!.isBefore(today());

  String get title => description.isNotEmpty ? description : t.order;

  Order copyWith({DateTime? doneAt, bool clearDone = false, String? photo, bool clearPhoto = false}) => Order(
        id: id,
        clientId: clientId,
        description: description,
        photo: clearPhoto ? null : (photo ?? this.photo),
        priceCents: priceCents,
        depositCents: depositCents,
        depositAt: depositAt,
        acceptedAt: acceptedAt,
        dueAt: dueAt,
        doneAt: clearDone ? null : (doneAt ?? this.doneAt),
        note: note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'description': description,
        'photo': photo,
        'amount_cents': priceCents,
        'deposit_cents': depositCents,
        'deposit_at': depositAt == null ? null : dateToDb(depositAt!),
        'accepted_at': dateToDb(acceptedAt),
        'due_at': dueAt == null ? null : dateToDb(dueAt!),
        'done_at': doneAt == null ? null : dateToDb(doneAt!),
        'note': note,
      };

  factory Order.fromMap(Map<String, Object?> m) => Order(
        id: m['id'] as int,
        clientId: m['client_id'] as int,
        description: (m['description'] as String?) ?? '',
        photo: m['photo'] as String?,
        priceCents: m['amount_cents'] as int,
        depositCents: (m['deposit_cents'] as int?) ?? 0,
        depositAt: dateFromDbOrNull(m['deposit_at']),
        acceptedAt: dateFromDb(m['accepted_at'] as String),
        dueAt: dateFromDbOrNull(m['due_at']),
        doneAt: dateFromDbOrNull(m['done_at']),
        note: (m['note'] as String?) ?? '',
      );
}

class Payment {
  final int? id;
  final int clientId;
  final int? orderId;
  final int amountCents;
  final DateTime paidAt;
  final String note;

  const Payment({
    this.id,
    required this.clientId,
    this.orderId,
    required this.amountCents,
    required this.paidAt,
    this.note = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'order_id': orderId,
        'amount_cents': amountCents,
        'paid_at': dateToDb(paidAt),
        'note': note,
      };

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
        id: m['id'] as int,
        clientId: m['client_id'] as int,
        orderId: m['order_id'] as int?,
        amountCents: m['amount_cents'] as int,
        paidAt: dateFromDb(m['paid_at'] as String),
        note: (m['note'] as String?) ?? '',
      );
}

class Expense {
  final int? id;
  final String category;
  final int amountCents;
  final DateTime spentAt;
  final String note;

  const Expense({
    this.id,
    required this.category,
    required this.amountCents,
    required this.spentAt,
    this.note = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category,
        'amount_cents': amountCents,
        'spent_at': dateToDb(spentAt),
        'note': note,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int,
        category: m['category'] as String,
        amountCents: m['amount_cents'] as int,
        spentAt: dateFromDb(m['spent_at'] as String),
        note: (m['note'] as String?) ?? '',
      );
}

/// Месяц (год + номер месяца).
class YearMonth implements Comparable<YearMonth> {
  final int year;
  final int month;

  const YearMonth(this.year, this.month);

  factory YearMonth.of(DateTime d) => YearMonth(d.year, d.month);
  factory YearMonth.now() => YearMonth.of(DateTime.now());

  YearMonth get prev => month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);
  YearMonth get next => month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);

  bool contains(DateTime d) => d.year == year && d.month == month;

  String get name => t.monthNames[month - 1];
  String get label => '$name $year';
  String get shortLabel => t.monthShort[month - 1];
  String get fileLabel => '$year-${month.toString().padLeft(2, '0')}';

  @override
  int compareTo(YearMonth o) => year != o.year ? year.compareTo(o.year) : month.compareTo(o.month);

  @override
  bool operator ==(Object o) => o is YearMonth && o.year == year && o.month == month;

  @override
  int get hashCode => year * 100 + month;
}

/// Итоги за месяц.
class MonthSummary {
  final YearMonth month;
  final int paymentsCents; // оплаты, полученные в месяце
  final int depositsCents; // залоги, полученные в месяце
  final int expenseCents; // расходы месяца
  final int ordersCents; // сумма заказов, принятых в месяце
  final int ordersCount;
  final Map<String, int> expensesByCategory;

  const MonthSummary({
    required this.month,
    required this.paymentsCents,
    required this.depositsCents,
    required this.expenseCents,
    required this.ordersCents,
    required this.ordersCount,
    required this.expensesByCategory,
  });

  int get incomeCents => paymentsCents + depositsCents;
  int get profitCents => incomeCents - expenseCents;
}
