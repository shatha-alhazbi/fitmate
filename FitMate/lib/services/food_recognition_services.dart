import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food.dart';
import 'package:fitmate/models/food_repository.dart';

class Food_recognition_service {
  final Food_repository _food_repository;
  bool _modelLoaded = false;

  Food_recognition_service(this._food_repository);

  /// Initialize the TFLite model
  Future<void> loadModel() async {
    if (_modelLoaded) return;
    
    try {
      await Tflite.loadModel(
        model: 'assets/models/food_model.tflite',
        labels: 'assets/models/probability-labels-en.txt',
      );
      _modelLoaded = true;
      debugPrint("Food recognition model loaded successfully");
    } catch (e) {
      debugPrint("Failed to load food recognition model: $e");
      rethrow;
    }
  }

  /// Recognize food from image
  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_modelLoaded) {
      await loadModel();
    }

    try {
      // Run inference on the image
      final List? recognitions = await Tflite.runModelOnImage(
        path: imageFile.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      if (recognitions == null || recognitions.isEmpty) {
        return {
          'success': false,
          'message': 'Unrecognizable food',
        };
      }

      // Get the top prediction
      final Map<String, dynamic> topPrediction = recognitions.first;
      final String foodName = topPrediction['label'].toString().split(' ').sublist(1).join(' ');
      final double confidence = topPrediction['confidence'];

      // Only proceed if confidence is reasonably high
      if (confidence < 0.65) {
        return {
          'success': false,
          'message': 'Unrecognizable food',
        };
      }

      // Fetch food details from repository
      final Food? food = await _food_repository.getFoodByName(foodName);
      
      if (food == null) {
        return {
          'success': false,
          'message': 'Food identified but details not found',
        };
      }

      return {
        'success': true,
        'food': food,
        'confidence': confidence
      };
    } catch (e) {
      debugPrint("Error during food recognition: $e");
      return {
        'success': false,
        'message': 'Error processing image',
      };
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_modelLoaded) {
      await Tflite.close();
      _modelLoaded = false;
    }
  }
}

// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'package:flutter/services.dart';


// class FoodRecognitionService {
//   Interpreter? _interpreter;
//   List<String> _labels = [];

//   /// Load the TFLite model and labels
//   Future<void> loadModel() async {
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/food_model.tflite');
//       _labels = await _loadLabels();
//       print("✅ TFLite model loaded successfully");
//     } catch (e) {
//       print("❌ Error loading model: $e");
//     }
//   }

//   /// Recognizes food from an image file
//   Future<String> recognizeFood(File imageFile) async {
//     if (_interpreter == null) {
//       return "❌ Model not loaded";
//     }

//     // Load and preprocess image
//     img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
//     if (image == null) {
//       return "❌ Error decoding image";
//     }
//     img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
//     List<List<List<List<double>>>> input = [_imageToByteList(resizedImage)];

//     // Prepare output tensor
//     var output = List.generate(1, (i) => List.filled(_labels.length, 0.0));

//     // Run inference
//     try {
//       _interpreter!.run(input, output);
//     } catch (e) {
//       return "❌ Error during inference: $e";
//     }

//     // Find the highest confidence prediction
//     int maxIndex = 0;
//     double maxConfidence = 0.0;
//     for (int i = 0; i < output[0].length; i++) {
//       if (output[0][i] > maxConfidence) {
//         maxConfidence = output[0][i];
//         maxIndex = i;
//       }
//     }

//     if (maxConfidence < 0.5) {
//       return "❌ Food not recognized";
//     }

//     return _labels[maxIndex];
//   }

//   /// Converts image to model-compatible byte list
//   List<List<List<double>>> _imageToByteList(img.Image image) {
//     return List.generate(
//       224,
//       (y) => List.generate(
//         224,
//         (x) {
//           var pixel = image.getPixel(x, y);
//           return [(pixel.r / 255.0), (pixel.g / 255.0), (pixel.b / 255.0)];
//         },
//       ),
//     );
//   }

//   /// Loads labels from assets

//   Future<List<String>> _loadLabels() async {
//     try {
//       final labelsData = await rootBundle.loadString('assets/models/probability-labels-en.txt');
//       return labelsData.split('\n').where((label) => label.isNotEmpty).toList();
//     } catch (e) {
//       print("❌ Error loading labels: $e");
//       return ["Unknown"];
//     }
//   }
// }