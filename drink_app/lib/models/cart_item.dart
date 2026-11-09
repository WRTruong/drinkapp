import 'drink.dart';

class CartItem {
  final Drink drink;
  int quantity;
  String size;
  String sugar;
  String ice;

  CartItem({required this.drink, this.quantity = 1,
            this.size = 'M', this.sugar = '100%', this.ice = '100%'});

  double get unitPrice => drink.priceForSize(size);
  double get lineTotal => unitPrice * quantity;
}