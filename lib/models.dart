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

/// Как считается сумма заказа.
enum Pricing {
  fixed('fixed', 'Сумма'),
  perKg('kg', 'За кг'),
  perUnit('unit', 'За шт');

  final String db;
  final String label;
  const Pricing(this.db, this.label);

  static Pricing fromDb(String? s) => Pricing.values.firstWhere((p) => p.db == s, orElse: () => Pricing.fixed);
}

/// Поля заказа, которые можно скрыть в настройках.
enum OrderField {
  description('description', 'Груз / описание'),
  code('code', 'Трек-номер / код'),
  weight('weight', 'Вес, кг'),
  quantity('quantity', 'Количество, шт'),
  pricing('pricing', 'Цена за кг / за шт'),
  extra('extra', 'Доплата / скидка'),
  done('done', 'Статус и дата выполнения'),
  note('note', 'Заметка');

  final String key;
  final String label;
  const OrderField(this.key, this.label);
}

/// Сумма заказа по тарифу. Для фиксированной цены возвращает null.
int? computeOrderAmount({
  required Pricing pricing,
  required int? rateCents,
  required double? weightKg,
  required int? quantity,
  int extraCents = 0,
}) {
  if (rateCents == null) return null;
  switch (pricing) {
    case Pricing.fixed:
      return null;
    case Pricing.perKg:
      if (weightKg == null) return null;
      return (weightKg * rateCents).round() + extraCents;
    case Pricing.perUnit:
      if (quantity == null) return null;
      return quantity * rateCents + extraCents;
  }
}

class Client {
  final int? id;
  final String name;
  final String phone;
  final String note;

  /// Личная цена за кг для этого клиента (если отличается от обычной).
  final int? rateKgCents;

  const Client({this.id, required this.name, this.phone = '', this.note = '', this.rateKgCents});

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'note': note,
        'rate_kg_cents': rateKgCents,
      };

  factory Client.fromMap(Map<String, Object?> m) => Client(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        rateKgCents: m['rate_kg_cents'] as int?,
      );
}

class Order {
  final int? id;
  final int clientId;
  final String description;
  final String code;
  final double? weightKg;
  final int? quantity;
  final Pricing pricing;

  /// Цена за кг или за шт (зависит от [pricing]).
  final int? rateCents;
  final int extraCents;

  /// Итоговая сумма заказа (для тарифа — уже посчитанная).
  final int amountCents;
  final DateTime acceptedAt;
  final DateTime? doneAt;
  final String note;

  const Order({
    this.id,
    required this.clientId,
    this.description = '',
    this.code = '',
    this.weightKg,
    this.quantity,
    this.pricing = Pricing.fixed,
    this.rateCents,
    this.extraCents = 0,
    required this.amountCents,
    required this.acceptedAt,
    this.doneAt,
    this.note = '',
  });

  bool get isDone => doneAt != null;

  String get title => description.isNotEmpty ? description : (code.isNotEmpty ? code : 'Заказ');

  Order copyWith({DateTime? doneAt, bool clearDone = false}) => Order(
        id: id,
        clientId: clientId,
        description: description,
        code: code,
        weightKg: weightKg,
        quantity: quantity,
        pricing: pricing,
        rateCents: rateCents,
        extraCents: extraCents,
        amountCents: amountCents,
        acceptedAt: acceptedAt,
        doneAt: clearDone ? null : (doneAt ?? this.doneAt),
        note: note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'client_id': clientId,
        'description': description,
        'code': code,
        'weight_kg': weightKg,
        'quantity': quantity,
        'pricing': pricing.db,
        'rate_cents': rateCents,
        'extra_cents': extraCents,
        'amount_cents': amountCents,
        'accepted_at': dateToDb(acceptedAt),
        'done_at': doneAt == null ? null : dateToDb(doneAt!),
        'note': note,
      };

  factory Order.fromMap(Map<String, Object?> m) => Order(
        id: m['id'] as int,
        clientId: m['client_id'] as int,
        description: (m['description'] as String?) ?? '',
        code: (m['code'] as String?) ?? '',
        weightKg: (m['weight_kg'] as num?)?.toDouble(),
        quantity: m['quantity'] as int?,
        pricing: Pricing.fromDb(m['pricing'] as String?),
        rateCents: m['rate_cents'] as int?,
        extraCents: (m['extra_cents'] as int?) ?? 0,
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

  static const names = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];
  static const short = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String get label => '${names[month - 1]} $year';
  String get name => names[month - 1];
  String get shortLabel => short[month - 1];
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
  final int weightedOrdersCents; // сумма заказов, у которых указан вес
  final Map<String, int> expensesByCategory;

  const MonthSummary({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
    required this.ordersCents,
    required this.ordersCount,
    required this.weightKg,
    required this.weightedOrdersCents,
    required this.expensesByCategory,
  });

  int get profitCents => incomeCents - expenseCents;

  /// Средняя цена за кг по заказам месяца (в центах), если есть вес.
  int? get avgPerKgCents => weightKg > 0 ? (weightedOrdersCents / weightKg).round() : null;

  bool get isEmpty => incomeCents == 0 && expenseCents == 0 && ordersCount == 0;
}
