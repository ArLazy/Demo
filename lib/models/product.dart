class Product {
  final int? id;
  final String name;
  final double protein;
  final double fat;
  final double carbs;
  final double calories;
  final String emoji;
  final bool isPreInstalled;

  Product({
    this.id,
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.emoji,
    this.isPreInstalled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'calories': calories,
      'emoji': emoji,
      'isPreInstalled': isPreInstalled ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      protein: map['protein'] as double,
      fat: map['fat'] as double,
      carbs: map['carbs'] as double,
      calories: map['calories'] as double,
      emoji: map['emoji'] as String,
      isPreInstalled: map['isPreInstalled'] == 1,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? protein,
    double? fat,
    double? carbs,
    double? calories,
    String? emoji,
    bool? isPreInstalled,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      calories: calories ?? this.calories,
      emoji: emoji ?? this.emoji,
      isPreInstalled: isPreInstalled ?? this.isPreInstalled,
    );
  }

  Map<String, dynamic> calculateBJU(double grams) {
    final multiplier = grams / 100;
    return {
      'protein': (protein * multiplier).toStringAsFixed(1),
      'fat': (fat * multiplier).toStringAsFixed(1),
      'carbs': (carbs * multiplier).toStringAsFixed(1),
      'calories': (calories * multiplier).toStringAsFixed(0),
      'grams': grams,
    };
  }
}