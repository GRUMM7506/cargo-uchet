import 'package:cargo_uchet/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseMoney / money', () {
    expect(parseMoney('1 250,5'), 125050);
    expect(parseMoney('\$40'), 4000);
    expect(parseMoney(''), isNull);
    expect(money(125050), '\$1 250.5');
    expect(money(-500), '−\$5');
  });
}
