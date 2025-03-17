class Food {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final String? imageUrl;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.imageUrl,
  });

  // Create a Food object from a JSON map
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fats: json['fats'].toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  // Convert a Food object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'imageUrl': imageUrl,
    };
  }

  // Create a copy of this Food with modified fields
  Food copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fats,
    String? imageUrl,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

// class Food {
//   final String name;
//   final double calories; // in kcal (calories)
//   final double protein;  // in grams
//   final double carbs;    // in grams
//   final double fat;      // in grams
//   final double servingSize; // in grams

//   Food({
//     required this.name,
//     required this.calories,
//     required this.protein,
//     required this.carbs,
//     required this.fat,
//     required this.servingSize,
//   });

//   // Firestore serialization
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'calories': calories,
//       'protein': protein,
//       'carbs': carbs,
//       'fat': fat,
//       'servingSize': servingSize,
//     };
//   }

//   factory Food.fromMap(Map<String, dynamic> map) {
//     return Food(
//       name: map['name'],
//       calories: map['calories'],
//       protein: map['protein'],
//       carbs: map['carbs'],
//       fat: map['fat'],
//       servingSize: map['servingSize'],
//     );
//   }
// }
