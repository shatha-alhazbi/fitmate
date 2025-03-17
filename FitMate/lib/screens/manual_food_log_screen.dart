import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food.dart';
import '../models/food_repository.dart';
import '../services/food_logging_service.dart'; 

class ManualFoodLogScreen extends StatefulWidget {
  const ManualFoodLogScreen({Key? key, this.initialFoodName}) : super(key: key);

  // Optional parameter to pre-fill the food name (e.g., when coming from failed recognition)
  final String? initialFoodName;

  @override
  _ManualFoodLogScreenState createState() => _ManualFoodLogScreenState();
}

class _ManualFoodLogScreenState extends State<ManualFoodLogScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _nameController;
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  
  // Portion size control
  double _portionSize = 1.0;
  
  // Search functionality
  List<Food>? _searchResults;
  bool _isSearching = false;
  
  // Recently used foods
  List<Food>? _recentFoods;
  bool _isLoadingRecent = true;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFoodName ?? '');
    _loadRecentFoods();
  }
  
  Future<void> _loadRecentFoods() async {
    setState(() {
      _isLoadingRecent = true;
    });
    
    try {
      // This would typically come from a local database or user preferences
      final repository = Provider.of<Food_repository>(context, listen: false);
      final foods = await repository.getAllFoods();
      
      // Sort by most recently used or most frequently used
      // This is a placeholder - replace with actual logic based on your app's data structure
      setState(() {
        _recentFoods = foods.take(5).toList();
        _isLoadingRecent = false;
      });
    } catch (e) {
      setState(() {
        _recentFoods = [];
        _isLoadingRecent = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recent foods: $e')),
      );
    }
  }
  
  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final repository = Provider.of<Food_repository>(context, listen: false);
      final foods = await repository.getAllFoods();
      
      // Filter foods based on search query
      final results = foods.where((food) => 
        food.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }
  
  Future<void> _selectFood(Food food) async {
    setState(() {
      _nameController.text = food.name;
      _caloriesController.text = food.calories.toString();
      _proteinController.text = food.protein.toString();
      _carbsController.text = food.carbs.toString();
      _fatsController.text = food.fats.toString();
      _searchResults = null;
    });
  }
  
  Future<void> _logFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      final food = Food(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        name: _nameController.text,
        calories: (int.parse(_caloriesController.text) * _portionSize).round(),
        protein: double.parse(_proteinController.text) * _portionSize,
        carbs: double.parse(_carbsController.text) * _portionSize,
        fats: double.parse(_fatsController.text) * _portionSize,
      );
      
      // Log the food using your API service
      final apiService = Provider.of<FoodLoggingService>(context, listen: false);
      await apiService.logFood(food);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food logged successfully!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log food: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Food Manually'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Food name with search
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Food Name',
                      hintText: 'e.g., Apple, Chicken Breast',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _nameController.clear();
                          setState(() {
                            _searchResults = null;
                          });
                        },
                      ),
                    ),
                    onChanged: _searchFoods,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a food name';
                      }
                      return null;
                    },
                  ),
                  
                  // Search results
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_searchResults != null && _searchResults!.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults!.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults![index];
                          return ListTile(
                            title: Text(food.name),
                            subtitle: Text('${food.calories} kcal | P: ${food.protein}g | C: ${food.carbs}g | F: ${food.fats}g'),
                            onTap: () => _selectFood(food),
                          );
                        },
                      ),
                    )
                  else if (_searchResults != null && _searchResults!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No foods found. Please enter nutrition details manually.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Nutrition details
                  TextFormField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      hintText: 'e.g., 100',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter calories';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _proteinController,
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            hintText: 'e.g., 5',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _carbsController,
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            hintText: 'e.g., 25',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fatsController,
                          decoration: const InputDecoration(
                            labelText: 'Fats (g)',
                            hintText: 'e.g., 0.5',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Portion size
                  Text(
                    'Portion Size: ${_portionSize.toStringAsFixed(2)}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _portionSize,
                    min: 0.25,
                    max: 3.0,
                    divisions: 11,
                    label: '${_portionSize.toStringAsFixed(2)}x',
                    onChanged: (value) {
                      setState(() {
                        _portionSize = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recently used foods
                  const Text(
                    'Recently Used Foods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingRecent)
                    const Center(child: CircularProgressIndicator())
                  else if (_recentFoods == null || _recentFoods!.isEmpty)
                    Text(
                      'No recent foods found',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _recentFoods!.length,
                        itemBuilder: (context, index) {
                          final food = _recentFoods![index];
                          return ListTile(
                            title: Text(food.name),
                            subtitle: Text('${food.calories} kcal | P: ${food.protein}g | C: ${food.carbs}g | F: ${food.fats}g'),
                            onTap: () => _selectFood(food),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: _logFood,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('LOG FOOD', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }
}