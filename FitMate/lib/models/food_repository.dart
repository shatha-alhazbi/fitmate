import 'package:cloud_firestore/cloud_firestore.dart';
import 'food.dart';

class Food_repository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'foods';
  
  // Get all foods from the database
  Future<List<Food>> getAllFoods() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Food.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error fetching foods: $e');
      return [];
    }
  }
  
  // Get a specific food by its name
  Future<Food?> getFoodByName(String name) async {
    try {
      // First try to find an exact match
      final QuerySnapshot exactMatch = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      
      if (exactMatch.docs.isNotEmpty) {
        final doc = exactMatch.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return Food.fromJson({...data, 'id': doc.id});
      }
      
      // If no exact match, try a case-insensitive search
      // Note: This is a naive approach. Firestore doesn't support case-insensitive
      // search directly, so we might need a more sophisticated approach in production
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get();
      
      final matchingDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final foodName = data['name'] as String;
        return foodName.toLowerCase() == name.toLowerCase();
      });
      
      if (matchingDocs.isNotEmpty) {
        final doc = matchingDocs.first;
        final data = doc.data() as Map<String, dynamic>;
        return Food.fromJson({...data, 'id': doc.id});
      }
      
      // If still no match, try to see if the name is contained within any food names
      final looseMatchingDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final foodName = data['name'] as String;
        return foodName.toLowerCase().contains(name.toLowerCase()) ||
               name.toLowerCase().contains(foodName.toLowerCase());
      });
      
      if (looseMatchingDocs.isNotEmpty) {
        final doc = looseMatchingDocs.first;
        final data = doc.data() as Map<String, dynamic>;
        return Food.fromJson({...data, 'id': doc.id});
      }
      
      // No match found
      return null;
    } catch (e) {
      print('Error fetching food by name: $e');
      return null;
    }
  }
  
  // Add a new food to the database
  Future<String?> addFood(Food food) async {
    try {
      final DocumentReference docRef = await _firestore.collection(_collectionName).add(food.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding food: $e');
      return null;
    }
  }
  
  // Update an existing food
  Future<bool> updateFood(Food food) async {
    try {
      await _firestore.collection(_collectionName).doc(food.id).update(food.toJson());
      return true;
    } catch (e) {
      print('Error updating food: $e');
      return false;
    }
  }
  
  // Delete a food
  Future<bool> deleteFood(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting food: $e');
      return false;
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fitmate/models/food.dart';

// class FoodRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> saveFood(Food food) async {
//     try {
//       await _firestore.collection('foods').add(food.toMap());
//     } catch (e) {
//       print('Error saving food: $e');
//     }
//   }

//   Future<List<Food>> getFoods() async {
//     try {
//       QuerySnapshot snapshot = await _firestore.collection('foods').get();

//       return snapshot.docs
//           .map((doc) => Food.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       print('Error fetching foods: $e');
//       return [];
//     }
//   }
// }
