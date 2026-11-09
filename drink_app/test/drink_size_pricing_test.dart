import 'package:flutter_test/flutter_test.dart';
import 'package:drink_app/models/drink.dart';

void main() {
  test('drink price changes with size', () {
    final drink = Drink(id: 1, name: 'Trà sữa', price: 30000);

    expect(drink.priceForSize('S'), 30000);
    expect(drink.priceForSize('M'), 35000);
    expect(drink.priceForSize('L'), 40000);
  });
}
