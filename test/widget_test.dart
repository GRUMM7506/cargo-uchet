import 'package:cargo_uchet/format.dart';
import 'package:cargo_uchet/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseMoney / money', () {
    expect(parseMoney('1 250,5'), 125050);
    expect(parseMoney('\$40'), 4000);
    expect(parseMoney('-5'), -500);
    expect(parseMoney(''), isNull);
    expect(money(125050), '\$1 250.5');
    expect(money(-500), '−\$5');
  });

  test('сумма заказа по тарифу', () {
    // 12.5 кг × $3.50 = $43.75
    expect(computeOrderAmount(pricing: Pricing.perKg, rateCents: 350, weightKg: 12.5, quantity: null), 4375);
    // + доплата $5
    expect(
      computeOrderAmount(pricing: Pricing.perKg, rateCents: 350, weightKg: 12.5, quantity: null, extraCents: 500),
      4875,
    );
    // скидка
    expect(
      computeOrderAmount(pricing: Pricing.perKg, rateCents: 300, weightKg: 10, quantity: null, extraCents: -200),
      2800,
    );
    // 3 шт × $20
    expect(computeOrderAmount(pricing: Pricing.perUnit, rateCents: 2000, weightKg: null, quantity: 3), 6000);
    // нет веса — нельзя посчитать
    expect(computeOrderAmount(pricing: Pricing.perKg, rateCents: 350, weightKg: null, quantity: 3), isNull);
    expect(computeOrderAmount(pricing: Pricing.fixed, rateCents: 350, weightKg: 1, quantity: 1), isNull);
  });

  test('средняя цена за кг', () {
    const s = MonthSummary(
      month: YearMonth(2026, 11),
      incomeCents: 0,
      expenseCents: 0,
      ordersCents: 10000,
      ordersCount: 2,
      weightKg: 25,
      weightedOrdersCents: 8750,
      expensesByCategory: {},
    );
    expect(s.avgPerKgCents, 350);
  });
}
