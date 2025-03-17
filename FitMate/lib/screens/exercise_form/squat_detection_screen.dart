import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'analyzers/squat_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'base_exercise_detection_screen.dart';
import 'package:fitmate/widgets/pose_painter.dart';

class SquatDetectionScreen extends BaseExerciseDetectionScreen {
  const SquatDetectionScreen({Key? key}) 
      : super(key: key, exerciseType: 'Squat');
  
  @override
  _SquatDetectionScreenState createState() => _SquatDetectionScreenState();
}

class _SquatDetectionScreenState extends BaseExerciseDetectionState<SquatDetectionScreen> {
  late SquatAnalyzer analyzer;
  
  @override
  void initState() {
    // Set preferred camera to front for squat detection
    preferredCameraLensDirection = CameraLensDirection.front;
    
    // Create analyzer before calling super.initState() which starts camera
    analyzer = SquatAnalyzer();
    
    super.initState();
  }
  
  @override
  Future<void> processPose(Pose pose) async {
    // Process pose using the squat analyzer
    analyzer.analyzePose(pose);
    // Update UI after processing
    if (mounted) setState(() {});
  }
  
  @override
  Widget buildExerciseUI() {
    return Stack(
      children: [
        // Camera Preview with proper aspect ratio
        Container(
          width: double.infinity,
          height: double.infinity,
          child: AspectRatio(
            aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
          ),
        ),
        
        // Pose overlay when pose is detected
        if (currentPose != null)
          CustomPaint(
            painter: PosePainter(
              pose: currentPose!,
              imageSize: Size(
                cameraController!.value.previewSize!.height,
                cameraController!.value.previewSize!.width,
              ),
              isFrontCamera: true,
            ),
            size: Size.infinite,
          ),
        
        // Top status row - Counter and Foot placement
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ExerciseUIComponents.buildStatusRow(
            statusBoxes: [
              // Reps counter
              ExerciseUIComponents.buildStatusBox(
                label: 'REPS',
                value: '${analyzer.counter}',
                color: Colors.blue,
                fontSize: 20,
              ),
              
              // Foot placement
              ExerciseUIComponents.buildStatusBox(
                label: 'FEET',
                value: analyzer.footPlacement,
                color: ExerciseUIComponents.getStatusColor(analyzer.footPlacement),
              ),
            ],
          ),
        ),
        
        // Second status row - Knee placement and Current stage
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: ExerciseUIComponents.buildStatusRow(
            statusBoxes: [
              // Knee placement
              ExerciseUIComponents.buildStatusBox(
                label: 'KNEES',
                value: analyzer.kneePlacement,
                color: ExerciseUIComponents.getStatusColor(analyzer.kneePlacement),
              ),
              
              // Current stage
              ExerciseUIComponents.buildStatusBox(
                label: 'STAGE',
                value: analyzer.currentStage.toUpperCase(),
                color: Colors.blue,
              ),
            ],
          ),
        ),
        
        // Debug info (can be removed in production)
        Positioned(
          top: 170,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            color: Colors.black.withOpacity(0.5),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Knee/Foot: ${analyzer.kneeFootRatio}, Foot/Shoulder: ${analyzer.footShoulderRatio}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom feedback and instructions
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Form feedback
              ExerciseUIComponents.buildFeedbackBox(
                feedbackText: analyzer.getFormFeedback(),
              ),
              
              // Position instruction
              ExerciseUIComponents.buildInstructionsBox(
                instructionsText: analyzer.getPositionInstructions(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}