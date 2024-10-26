class MealKit {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final String recipe;
  final double price;
  final String imageUrl; // New property for image URL

  MealKit({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.recipe,
    required this.price,
    required this.imageUrl, // Default to an empty string
  });

  factory MealKit.fromMap(Map<String, dynamic> map) {
    return MealKit(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      recipe: map['recipe'] ?? '',
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] ?? '', // Assign image URL
    );
  }
}
