import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //sharifa
import 'screens/login_screens/login_screen.dart';
import 'screens/login_screens/forgot_password_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/register_screens/age_question.dart';
import 'screens/home_page.dart';
import 'services/workout_service.dart'; // Added for workout generation
//sharifa
import 'models/food_repository.dart'; // Added for food recognition
import 'services/food_recognition_services.dart'; // Added for food recognition
import 'screens/food_recognition/food_recognition_screen.dart';
import 'screens/manual_food_log_screen.dart'; // Added for manual food logging
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  // Ensure widgets are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Register the FoodRepository
        Provider<Food_repository>(
          create: (_) => Food_repository(),
        ),
        // Register the FoodRecognitionService, which depends on FoodRepository
        ProxyProvider<Food_repository, Food_recognition_service>(
          update: (_, foodRepo, __) => Food_recognition_service(foodRepo),
        ),
        // Add other providers here as needed
        Provider<WorkoutService>(
          create: (_) => WorkoutService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: WelcomePage(),
        routes: {
          '/login': (context) => LoginPage(),
          '/forgot-password': (context) => ForgotPasswordPage(),
          '/register': (context) => AgeQuestionPage(age: 0),
          '/home': (context) => HomePage(),
          '/food_recognition': (context) => FoodRecognitionScreen(),
          '/manual_food_log': (context) => ManualFoodLogScreen(),
        },
      ),
    );
  }
}