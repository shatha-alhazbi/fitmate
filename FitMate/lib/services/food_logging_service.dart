import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food.dart';
import 'package:flutter/material.dart';

class FoodLoggingService {

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --------------------  sharifa : FOOD LOGGING FUNCTIONS --------------------
  
  // Log food to user's nutrition logs
  Future<void> logFood(Food food) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get current date in YYYY-MM-DD format
      final date = DateTime.now();
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Add timestamp to the food data
      final foodData = food.toJson();
      foodData['timestamp'] = FieldValue.serverTimestamp();
      foodData['loggedAt'] = DateTime.now().toIso8601String();
      
      // Add to Firestore
      await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(formattedDate)
        .collection('foods')
        .add(foodData);
        
      // Update daily nutrition totals
      await _updateDailyNutritionTotals(user.uid, formattedDate, food);
      
      debugPrint('Food logged successfully: ${food.name}');
    } catch (e) {
      debugPrint('Error logging food: $e');
      rethrow;
    }
  }
  
  // Update the daily nutrition totals
  Future<void> _updateDailyNutritionTotals(String userId, String date, Food food) async {
    try {
      // Reference to the daily log document
      final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('nutritionLogs')
        .doc(date);
      
      // Get the current totals
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Update existing totals
        final data = docSnapshot.data() as Map<String, dynamic>;
        
        await docRef.update({
          'totalCalories': (data['totalCalories'] ?? 0) + food.calories,
          'totalProtein': (data['totalProtein'] ?? 0) + food.protein,
          'totalCarbs': (data['totalCarbs'] ?? 0) + food.carbs,
          'totalFats': (data['totalFats'] ?? 0) + food.fats,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new totals document
        await docRef.set({
          'date': date,
          'totalCalories': food.calories,
          'totalProtein': food.protein,
          'totalCarbs': food.carbs,
          'totalFats': food.fats,
          'created': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating daily nutrition totals: $e');
      // We don't rethrow here to prevent the food logging from failing
      // if only the totals update fails
    }
  }
  
  // Get the list of foods logged for a specific day
  Future<List<Food>> getDailyFoodLog([DateTime? date]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Use provided date or current date
      final logDate = date ?? DateTime.now();
      final formattedDate = '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
      
      // Query Firestore
      final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(formattedDate)
        .collection('foods')
        .orderBy('timestamp', descending: true)
        .get();
      
      // Convert to Food objects
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Food.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('Error getting daily food log: $e');
      return [];
    }
  }
  
  // Delete a logged food item
  Future<bool> deleteLoggedFood(String foodId, [DateTime? date]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Use provided date or current date
      final logDate = date ?? DateTime.now();
      final formattedDate = '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
      
      // Get the food data before deleting (to update totals)
      final foodDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(formattedDate)
        .collection('foods')
        .doc(foodId)
        .get();
      
      if (!foodDoc.exists) {
        return false;
      }
      
      final foodData = foodDoc.data() as Map<String, dynamic>;
      final food = Food.fromJson({...foodData, 'id': foodId});
      
      // Delete the food document
      await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(formattedDate)
        .collection('foods')
        .doc(foodId)
        .delete();
      
      // Update the daily totals by subtracting this food's values
      await _subtractFromDailyNutritionTotals(user.uid, formattedDate, food);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting logged food: $e');
      return false;
    }
  }
  
  // Subtract a food's nutrition values from the daily totals
  Future<void> _subtractFromDailyNutritionTotals(String userId, String date, Food food) async {
    try {
      final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('nutritionLogs')
        .doc(date);
      
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        
        await docRef.update({
          'totalCalories': (data['totalCalories'] ?? 0) - food.calories,
          'totalProtein': (data['totalProtein'] ?? 0) - food.protein,
          'totalCarbs': (data['totalCarbs'] ?? 0) - food.carbs,
          'totalFats': (data['totalFats'] ?? 0) - food.fats,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating daily nutrition totals after deletion: $e');
    }
  }
  
  // Get daily nutrition summary
  Future<Map<String, dynamic>> getDailyNutritionSummary([DateTime? date]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Use provided date or current date
      final logDate = date ?? DateTime.now();
      final formattedDate = '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
      
      final docSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nutritionLogs')
        .doc(formattedDate)
        .get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return {
          'date': formattedDate,
          'totalCalories': 0,
          'totalProtein': 0,
          'totalCarbs': 0,
          'totalFats': 0
        };
      }
    } catch (e) {
      debugPrint('Error getting daily nutrition summary: $e');
      return {
        'error': 'Failed to load nutrition data',
        'totalCalories': 0,
        'totalProtein': 0,
        'totalCarbs': 0,
        'totalFats': 0
      }; 
      }
  }

}
/*
When you use the logFood() method in the ApiService class, it will automatically:

Create the appropriate collections and documents in Firestore following that structure
Store food data at the appropriate location for each user
Maintain daily summary documents with nutrition totals

/users/{userId}/nutritionLogs/{date}/foods/{foodId}
/users/{userId}/nutritionLogs/{date} (summary document)

*/