import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/screens/exercise_form/bicep_curl_detection_screen.dart';
import 'package:fitmate/screens/exercise_form/squat_detection_screen.dart';
import 'package:fitmate/screens/exercise_form/plank_detection_screen.dart';

class FormInstructionsPage extends StatefulWidget {
  final String title;
  final String image;

  const FormInstructionsPage({Key? key, required this.title, required this.image}) : super(key: key);

  @override
  _FormInstructionsPageState createState() => _FormInstructionsPageState();
}

class _FormInstructionsPageState extends State<FormInstructionsPage> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Get instructions based on exercise type
  Map<String, String> _getInstructions() {
    switch (widget.title.toLowerCase()) {
      case 'squat':
        return {
          'instructions': '1. Stand straight with feet hip-width apart.\n'
                  '2. Engage your core muscles.\n'
                  '3. Lower down, as if sitting in an invisible chair.\n'
                  '4. Lift back up to standing position.',
          'tips': 'Keep your knees aligned with your toes. Maintain a neutral spine position.'
        };
      case 'plank':
        return {
          'instructions': '1. Start in a forearm plank position with elbows directly under shoulders.\n'
                  '2. Keep your body in a straight line from head to heels.\n'
                  '3. Engage your core and glutes to maintain stability.\n'
                  '4. Hold the position for the desired duration.',
          'tips': 'Breathe steadily. Avoid letting your hips sag or pike up. Keep your gaze slightly forward, not down.'
        };
      case 'lunge':
        return {
          'instructions': '1. Stand straight with feet hip-width apart.\n'
                  '2. Step forward with one leg and lower your body.\n'
                  '3. Both knees should form 90° angles at the bottom.\n'
                  '4. Push back up and return to starting position.',
          'tips': 'Keep your torso upright. Make sure your front knee doesn\'t extend past your toes.'
        };
      case 'bicep curl':
        return {
          'instructions': '1. Start in forearm position with elbows under shoulders.\n'
                  '2. Form a straight line from head to heels.\n'
                  '3. Engage core and glutes to maintain position.\n'
                  '4. Hold the position for the desired time.',
          'tips': 'Breathe steadily. Don\'t let your hips sag or pike up. Look slightly forward, not down.'
        };
      default:
        return {
          'instructions': '1. Follow proper form for this exercise.\n'
                  '2. Maintain correct posture throughout.\n'
                  '3. Focus on controlled movement.\n'
                  '4. Complete the required repetitions.',
          'tips': 'Start with lighter weights if needed. Prioritize form over speed or weight.'
        };
    }
  }

  // Determine the appropriate camera detection screen to navigate to
  Widget _getDetectionScreen() {
    switch (widget.title.toLowerCase()) {
      case 'squat':
        return SquatDetectionScreen();
      case 'bicep curl':
        return BicepCurlDetectionScreen();
      case 'plank':
        return PlankDetectionScreen();
      default:
        return SquatDetectionScreen();
    }
  }
  
  // Determine if form detection is available for this exercise
  bool _isDetectionAvailable() {
    // List of exercises that have form detection implemented
    final List<String> availableExercises = ['squat','bicep curl','plank'];
    return availableExercises.contains(widget.title.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final instructions = _getInstructions();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Instructions',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(widget.image, width: 150, height: 150),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How to do it:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                instructions['instructions'] ?? '',
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 15),
              const Text(
                'Tips:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                instructions['tips'] ?? '',
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isDetectionAvailable() ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _getDetectionScreen(),
                  ),
                );
              } : null, // Disable button if detection is not available
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetectionAvailable() ? const Color(0xFFD2EB50) : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: Text(
                _isDetectionAvailable() ? 'START' : 'FORM DETECTION COMING SOON',
                style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}