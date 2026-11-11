import 'package:cargo_uchet/format.dart';
import 'package:cargo_uchet/l10n.dart';
import 'package:cargo_uchet/models.dart';
import 'package:cargo_uchet/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseMoney / money', () {
    expect(parseMoney('1 250,5'), 125050);
    expect(parseMoney('\$40'), 4000);
    expect(parseMoney(''), isNull);
    expect(money(125050), '\$1 250.5');
    expect(money(-500), '−\$5');
  });

  test('итоги месяца: приход = залоги + оплаты', () {
    const s = MonthSummary(
      month: YearMonth(2026, 11),
      paymentsCents: 30000,
      depositsCents: 15000,
      expenseCents: 20000,
      ordersCents: 90000,
      ordersCount: 2,
      expensesByCategory: {},
    );
    expect(s.incomeCents, 45000);
    expect(s.profitCents, 25000);
  });

  test('заказ: дата залога и просрочка', () {
    final accepted = DateTime(2026, 11, 1);
    final o = Order(clientId: 1, priceCents: 1000, depositCents: 300, acceptedAt: accepted);
    expect(o.depositDate, accepted);
    final o2 = Order(
      clientId: 1,
      priceCents: 1000,
      acceptedAt: accepted,
      depositAt: DateTime(2026, 11, 3),
      dueAt: today().subtract(const Duration(days: 1)),
    );
    expect(o2.depositDate, DateTime(2026, 11, 3));
    expect(o2.isOverdue, isTrue);
    expect(o2.copyWith(doneAt: today()).isOverdue, isFalse);
  });

  test('переводы есть на обоих языках', () {
    AppSettings.I.lang = 'ru';
    expect(t.tabClients, 'Клиенты');
    expect(t.clientsCount(1), '1 клиент');
    expect(t.clientsCount(3), '3 клиента');
    expect(t.clientsCount(11), '11 клиентов');
    AppSettings.I.lang = 'uz';
    expect(t.tabClients, 'Mijozlar');
    expect(t.dayMonth(12, 11), '12-noyabr');
    expect(const YearMonth(2026, 11).label, 'Noyabr 2026');
    AppSettings.I.lang = 'ru';
  });
}
