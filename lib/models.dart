// Модели данных. Все суммы хранятся в центах (int), чтобы не было ошибок округления.

String dateToDb(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateFromDb(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class Client {
  final int? id;
  final String name;
  final String phone;
  final String note;

  const Client({this.id, required this.name, this.phone = '', this.note = ''});

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'note': note,
      };

  factory Client.fromMap(Map<String, Object?> m) => Client(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
      );
}

class Order {
  final int? id;
  final int clientId;
  final String description;
  final double? weightKg;
  final int? quantity;
  final int amountCents;
  final DateTime acceptedAt;
  final DateTime? doneAt;
  final String note;

  const Order({
    this.id,
    required this.clientId,
    required this.description,
    this.weightKg,
    this.quantity,
    required this.amountCents,
    required this.acceptedAt,
    this.doneAt,
    this.note = '',
  });

  bool get isDone => doneAt != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'description': description,
        'weight_kg': weightKg,
        'quantity': quantity,
        'amount_cents': amountCents,
        'accepted_at': dateToDb(acceptedAt),
        'done_at': doneAt == null ? null : dateToDb(doneAt!),
        'note': note,
      };

  factory Order.fromMap(Map<String, Object?> m) => Order(
        id: m['id'] as int,
        clientId: m['client_id'] as int,
        description: (m['description'] as String?) ?? '',
        weightKg: (m['weight_kg'] as num?)?.toDouble(),
        quantity: m['quantity'] as int?,
        amountCents: m['amount_cents'] as int,
        acceptedAt: dateFromDb(m['accepted_at'] as String),
        doneAt: m['done_at'] == null ? null : dateFromDb(m['done_at'] as String),
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

  static const _names = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  String get label => '${_names[month - 1]} $year';
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
  final int incomeCents; // оплаты, полученные в месяце
  final int expenseCents; // расходы месяца
  final int ordersCents; // сумма заказов, принятых в месяце
  final int ordersCount;
  final double weightKg;
  final Map<String, int> expensesByCategory;

  const MonthSummary({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
    required this.ordersCents,
    required this.ordersCount,
    required this.weightKg,
    required this.expensesByCategory,
  });

  int get profitCents => incomeCents - expenseCents;
}
