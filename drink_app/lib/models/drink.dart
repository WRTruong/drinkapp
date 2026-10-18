class Drink {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  Drink({required this.id, required this.name, this.description,
         required this.price, this.imageUrl});

  factory Drink.fromJson(Map<String, dynamic> j) => Drink(
    id: j['id'],
    name: j['name'],
    description: j['description'],
    price: (j['price'] as num).toDouble(),
    imageUrl: j['imageUrl'],
  );
}