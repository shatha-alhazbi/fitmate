import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitmate/services/food_recognition_services.dart';
import 'package:fitmate/services/food_logging_service.dart';
import 'package:fitmate/models/food.dart';
import 'package:fitmate/screens/daily_nutrition_screen.dart';
import 'package:provider/provider.dart';

class FoodRecognitionScreen extends StatefulWidget {
  const FoodRecognitionScreen({Key? key}) : super(key: key);

  @override
  _FoodRecognitionScreenState createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  bool _isModelLoading = true;
  Food? _recognizedFood;
  double _portionSize = 1.0; // Default portion size
  String? _errorMessage;
  bool _modelLoadFailed = false;
  bool _networkError = false;
  late Food_recognition_service _foodRecognitionService;
  
  // Permission state
  bool _cameraPermissionChecked = false;
  bool _cameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _foodRecognitionService = Provider.of<Food_recognition_service>(context, listen: false);
    _checkCameraPermission(); // Check camera permission on initialization
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isModelLoading = true;
      _modelLoadFailed = false;
      _errorMessage = null;
    });

    try {
      await _foodRecognitionService.loadModel();
      setState(() {
        _isModelLoading = false;
      });
    } catch (e) {
      setState(() {
        _isModelLoading = false;
        _modelLoadFailed = true;
        _errorMessage = "Failed to initialize food recognition model: ${e.toString()}";
      });
    }
  }

  // Check camera permission status
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraPermissionChecked = true;
      _cameraPermissionGranted = status.isGranted;
    });
    
    // If not granted and not yet determined, show explanation
    if (!status.isGranted && status.isDenied) {
      _showPermissionExplanationDialog();
    } else if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  // Show explanation dialog for camera permission
  Future<void> _showPermissionExplanationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'FitMate needs camera access to identify food items and provide '
            'accurate nutrition information. This helps track your diet and '
            'meet your health goals.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Grant Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestCameraPermission();
              },
            ),
          ],
        );
      },
    );
  }

  // Show settings dialog when permission is permanently denied
  Future<void> _showOpenSettingsDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'FitMate needs camera access to identify food. Please enable camera '
            'permissions in your device settings to use this feature.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // Check permission again after returning from settings
                await Future.delayed(const Duration(seconds: 1));
                await _checkCameraPermission();
              },
            ),
          ],
        );
      },
    );
  }

  // Request camera permission
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });
    
    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  // Try again after error
  void _retryAfterError() {
    if (_modelLoadFailed) {
      _initializeModel();
    } else if (_networkError) {
      // Reset network error state
      setState(() {
        _networkError = false;
        _errorMessage = null;
      });
    } else {
      // Clear any other errors
      setState(() {
        _errorMessage = null;
      });
    }
  }

  // Modified to check permission before taking photo
  Future<void> _takePhoto() async {
    // Check permission first
    if (!_cameraPermissionGranted) {
      await _requestCameraPermission();
      if (!_cameraPermissionGranted) return; // Exit if permission still not granted
    }

    // Check if model is loaded
    if (_isModelLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, food recognition model is still loading...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_modelLoadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food recognition model failed to load. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _imageFile = File(photo.path);
        _recognizedFood = null;
        _portionSize = 1.0;
      });

      try {
        final result = await _foodRecognitionService.recognizeFood(_imageFile!);
        
        setState(() {
          _isProcessing = false;
          _networkError = false;
          
          if (result['success']) {
            _recognizedFood = result['food'];
            _errorMessage = null;
          } else {
            _errorMessage = result['message'];
            // If we couldn't recognize the food, show option to try again or use manual entry
            _showRecognitionFailedDialog();
          }
        });
      } catch (e) {
        setState(() {
          _isProcessing = false;
          _networkError = true;
          _errorMessage = "Error processing image: ${e.toString()}";
        });
        _showNetworkErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Camera error: ${e.toString()}";
      });
    }
  }

  // Show dialog when food recognition fails
  void _showRecognitionFailedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Food Recognition Failed'),
          content: const Text(
            'We couldn\'t identify the food in the image. You can try taking another photo '
            'with better lighting or use manual entry instead.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
            ),
            TextButton(
              child: const Text('Manual Entry'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/manual_food_log');
              },
            ),
          ],
        );
      },
    );
  }

  // Show dialog when network error occurs
  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Error'),
          content: const Text(
            'There was a problem connecting to the food recognition service. '
            'Please check your internet connection and try again.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
            ),
            TextButton(
              child: const Text('Manual Entry'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/manual_food_log');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logFood() async {
    if (_recognizedFood == null) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    
    try {
      // Scale nutrition values based on portion size
      final Food adjustedFood = Food(
        id: _recognizedFood!.id,
        name: _recognizedFood!.name,
        calories: (_recognizedFood!.calories * _portionSize).round(),
        protein: _recognizedFood!.protein * _portionSize,
        carbs: _recognizedFood!.carbs * _portionSize,
        fats: _recognizedFood!.fats * _portionSize,
        imageUrl: _recognizedFood!.imageUrl,
      );
      
      // Log the food to Firebase or local database
      final loggingService = Provider.of<FoodLoggingService>(context, listen: false);
      await loggingService.logFood(adjustedFood);
      
      setState(() {
        _isProcessing = false;
      });
      
      // Show success message and navigate to nutrition screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food logged successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to nutrition screen after successful logging
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DailyNutritionScreen(),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Failed to log food: ${e.toString()}";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log food: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Recognition'),
        actions: [
          // Help icon for permission information
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showPermissionExplanationDialog();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show permission UI if not granted
    if (_cameraPermissionChecked && !_cameraPermissionGranted) {
      return _buildPermissionRequestUI();
    }

    // Show loading UI when model is loading
    if (_isModelLoading) {
      return _buildLoadingUI('Loading food recognition model...');
    }

    // Show error UI if model failed to load
    if (_modelLoadFailed) {
      return _buildErrorUI(
        icon: Icons.error_outline,
        title: 'Model Loading Failed',
        message: _errorMessage ?? 'Failed to initialize food recognition model.',
        buttonText: 'Retry Loading',
        onRetry: _initializeModel,
      );
    }

    // Show processing UI when analyzing food
    if (_isProcessing) {
      return _buildLoadingUI('Analyzing your food...');
    }

    // Regular UI when permission is granted and model is loaded
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Camera preview or image display
          if (_imageFile != null)
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Take a photo of your food to recognize it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Position your food in good lighting for best results',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Error message (if any but not severe enough for a full error UI)
          if (_errorMessage != null && !_modelLoadFailed && !_networkError)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _retryAfterError,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            
          // Recognized food details
          if (_recognizedFood != null)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      _recognizedFood!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Nutrition Information:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildNutritionRow('Calories', '${(_recognizedFood!.calories * _portionSize).round()} kcal'),
                  _buildNutritionRow('Protein', '${(_recognizedFood!.protein * _portionSize).toStringAsFixed(1)} g'),
                  _buildNutritionRow('Carbs', '${(_recognizedFood!.carbs * _portionSize).toStringAsFixed(1)} g'),
                  _buildNutritionRow('Fats', '${(_recognizedFood!.fats * _portionSize).toStringAsFixed(1)} g'),
                  
                  const SizedBox(height: 20),
                  const Text(
                    'Adjust Portion Size:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  Center(
                    child: Text(
                      '${(_portionSize).toStringAsFixed(2)}x portion',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 20),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_recognizedFood != null && !_isProcessing) ? _logFood : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Log Food'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manual_food_log');
              },
              child: const Text('Enter Food Manually Instead'),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // UI for permission request
Widget _buildPermissionRequestUI() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(  // Removed `const` since Icons is not constant
            Icons.camera_alt, // Corrected from 'camera_alt_off'
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Camera Permission Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 10),
            const Text(
              'FitMate needs camera access to identify food items and provide '
              'accurate nutrition information.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Grant Camera Permission'),
              onPressed: _requestCameraPermission,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manual_food_log');
              },
              child: const Text('Continue with Manual Entry Instead'),
            ),
          ],
        ),
      ),
    );
  }

  // UI for loading state
  Widget _buildLoadingUI(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (message.contains('model'))
            const Text(
              'This may take a moment as we prepare the food recognition system.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // UI for error state
  Widget _buildErrorUI({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(buttonText),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manual_food_log');
              },
              child: const Text('Continue with Manual Entry Instead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:fitmate/services/food_recognition_services.dart';
// import 'package:fitmate/screens/logFoodManually.dart';


// class FoodRecognitionScreen extends StatefulWidget {
//   @override
//   _FoodRecognitionScreenState createState() => _FoodRecognitionScreenState();
// }

// class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
//   File? _image;
//   String _result = "";
//   bool _isRecognized = false;
//   final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();

//   @override
//   void initState() {
//     super.initState();
//     _foodRecognitionService.loadModel();
//   }

//   /// Opens the camera and captures an image
//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         _result = "Recognizing...";
//         _isRecognized = false;
//       });
//       _recognizeFood();
//     }
//   }

//   /// Runs the image through the TFLite model
//   Future<void> _recognizeFood() async {
//     if (_image == null) return;
//     String prediction = await _foodRecognitionService.recognizeFood(_image!);
    
//     setState(() {
//       _result = prediction;
//       _isRecognized = prediction != "❌ Food not recognized";
//     });

//     if (!_isRecognized) {
//       // Redirect to manual logging if unrecognized
//       Future.delayed(Duration(seconds: 2), () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => LogFoodManuallyScreen()),
//         );
//       });
//     }
//   }

//   /// Saves recognized food to Firestore (Implementation required)
//   void _saveFoodToFirestore() {
//     // TODO: Implement Firestore save logic here
//     print("✅ Food saved to Firestore: $_result");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Food Recognition")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _image == null 
//                 ? Text("Take a picture of food")
//                 : Image.file(_image!, width: 250, height: 250),
//             SizedBox(height: 20),
            
//             Text(_result, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

//             SizedBox(height: 20),

//             ElevatedButton(onPressed: _pickImage, child: Text("Capture Food")),

//             SizedBox(height: 20),

//             if (!_isRecognized)
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => LogFoodManuallyScreen()),
//                   );
//                 },
//                 child: Text("Log Food Manually"),
//               ),

//             if (_isRecognized)
//               Column(
//                 children: [
//                   Text("Macros & Portion Details Here", style: TextStyle(fontSize: 16, color: Colors.grey)),
//                   SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: _saveFoodToFirestore,
//                     child: Text("Save Food"),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
