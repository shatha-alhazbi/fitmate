/**
	•	Display all foods logged for the current day
	•	Show nutrition totals (calories, protein, carbs, fats)
	•	Allow users to delete logged foods
	•	Show progress toward nutrition goals */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/food.dart';
import '../services/food_logging_service.dart';

class DailyNutritionScreen extends StatefulWidget {
  const DailyNutritionScreen({Key? key}) : super(key: key);

  @override
  _DailyNutritionScreenState createState() => _DailyNutritionScreenState();
}

class _DailyNutritionScreenState extends State<DailyNutritionScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Food> _foodLogs = [];
  Map<String, dynamic> _nutritionSummary = {};
  bool _isLoading = true;
  
  // Default nutrition goals - in a real app, these would come from user settings
  final Map<String, dynamic> _nutritionGoals = {
    'calories': 2500,
    'protein': 150,
    'carbs': 300,
    'fats': 80,
  };

  @override
  void initState() {
    super.initState();
    _loadFoodLogs();
  }
  
  Future<void> _loadFoodLogs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = Provider.of<FoodLoggingService>(context, listen: false);
      
      // Load food logs for the selected date
      final logs = await apiService.getDailyFoodLog(_selectedDate);
      
      // Load nutrition summary
      final summary = await apiService.getDailyNutritionSummary(_selectedDate);
      
      setState(() {
        _foodLogs = logs;
        _nutritionSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load nutrition data: $e')),
      );
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFD2EB50),
            colorScheme: const ColorScheme.light(primary: Color(0xFFD2EB50)),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadFoodLogs();
    }
  }
  
  Future<void> _deleteFood(Food food) async {
    try {
      final apiService = Provider.of<FoodLoggingService>(context, listen: false);
      final success = await apiService.deleteLoggedFood(food.id, _selectedDate);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food removed from log')),
        );
        _loadFoodLogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove food')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  double _calculateProgress(String nutrient) {
    if (_nutritionGoals[nutrient] == 0) return 0.0;
    
    final value = _nutritionSummary['total${nutrient.capitalize()}'] ?? 0;
    final goal = _nutritionGoals[nutrient] ?? 1;
    
    // Cap at 1.0 to prevent progress indicators from going over 100%
    return (value / goal).clamp(0.0, 1.0);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Nutrition'),
        backgroundColor: const Color(0xFFD2EB50),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to food logging options
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Scan Food'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/food_recognition')
                            .then((_) => _loadFoodLogs());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Enter Manually'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/manual_food_log')
                            .then((_) => _loadFoodLogs());
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD2EB50)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date display
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nutrition Summary Cards
                  _buildNutritionSummary(),
                  const SizedBox(height: 24),
                  
                  // Food log header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FOOD LOG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_foodLogs.length} items',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Food log list
                  _foodLogs.isEmpty
                      ? _buildEmptyState()
                      : _buildFoodLogList(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildNutritionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calories
          _buildNutrientProgress(
            label: 'Calories',
            current: _nutritionSummary['totalCalories'] ?? 0,
            goal: _nutritionGoals['calories'],
            progress: _calculateProgress('calories'),
            unit: 'kcal',
            color: const Color(0xFFD2EB50),
          ),
          const Divider(),
          
          // Macronutrients
          Row(
            children: [
              Expanded(
                child: _buildNutrientProgress(
                  label: 'Protein',
                  current: _nutritionSummary['totalProtein'] ?? 0,
                  goal: _nutritionGoals['protein'],
                  progress: _calculateProgress('protein'),
                  unit: 'g',
                  color: Colors.redAccent,
                  isCompact: true,
                ),
              ),
              Expanded(
                child: _buildNutrientProgress(
                  label: 'Carbs',
                  current: _nutritionSummary['totalCarbs'] ?? 0,
                  goal: _nutritionGoals['carbs'],
                  progress: _calculateProgress('carbs'),
                  unit: 'g',
                  color: Colors.blueAccent,
                  isCompact: true,
                ),
              ),
              Expanded(
                child: _buildNutrientProgress(
                  label: 'Fats',
                  current: _nutritionSummary['totalFats'] ?? 0,
                  goal: _nutritionGoals['fats'],
                  progress: _calculateProgress('fats'),
                  unit: 'g',
                  color: Colors.orangeAccent,
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutrientProgress({
    required String label,
    required num current,
    required num goal,
    required double progress,
    required String unit,
    required Color color,
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: progress,
            backgroundColor: Colors.grey[200],
            progressColor: color,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.toStringAsFixed(1)}/$goal $unit',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${current.toStringAsFixed(0)}/$goal $unit',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 12.0,
          percent: progress,
          backgroundColor: Colors.grey[200],
          progressColor: color,
          padding: EdgeInsets.zero,
          barRadius: const Radius.circular(6),
          center: Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFoodLogList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _foodLogs.length,
      itemBuilder: (context, index) {
        final food = _foodLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD2EB50).withOpacity(0.2),
              child: const Icon(
                Icons.restaurant,
                color: Color(0xFFD2EB50),
              ),
            ),
            title: Text(
              food.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Calories: ${food.calories} kcal | P: ${food.protein.toStringAsFixed(1)}g | C: ${food.carbs.toStringAsFixed(1)}g | F: ${food.fats.toStringAsFixed(1)}g',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.redAccent,
              onPressed: () => _showDeleteConfirmation(food),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No foods logged for this day',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your meals',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Scan Food'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/food_recognition')
                            .then((_) => _loadFoodLogs());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Enter Manually'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/manual_food_log')
                            .then((_) => _loadFoodLogs());
                      },
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('LOG FOOD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2EB50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(Food food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Food'),
        content: Text('Are you sure you want to remove ${food.name} from your food log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFood(food);
            },
            child: const Text(
              'REMOVE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}