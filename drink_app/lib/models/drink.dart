class Drink {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  Drink(
      {required this.id,
      required this.name,
      this.description,
      required this.price,
      this.imageUrl,
      this.isAvailable = true});

  factory Drink.fromJson(Map<String, dynamic> j) => Drink(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        price: (j['price'] as num).toDouble(),
        imageUrl: j['imageUrl'],
        isAvailable: j['isAvailable'] as bool? ?? true,
      );
}
