class BjuRecord {
  final int? id;
  final int productId;
  final String productName;
  final double grams;
  final double protein;
  final double fat;
  final double carbs;
  final double calories;
  final DateTime dateTime;

  BjuRecord({
    this.id,
    required this.productId,
    required this.productName,
    required this.grams,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'grams': grams,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'calories': calories,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory BjuRecord.fromMap(Map<String, dynamic> map) {
    return BjuRecord(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      grams: map['grams'] as double,
      protein: map['protein'] as double,
      fat: map['fat'] as double,
      carbs: map['carbs'] as double,
      calories: map['calories'] as double,
      dateTime: DateTime.parse(map['dateTime'] as String),
    );
  }

  BjuRecord copyWith({
    int? id,
    int? productId,
    String? productName,
    double? grams,
    double? protein,
    double? fat,
    double? carbs,
    double? calories,
    DateTime? dateTime,
  }) {
    return BjuRecord(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      grams: grams ?? this.grams,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      calories: calories ?? this.calories,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}