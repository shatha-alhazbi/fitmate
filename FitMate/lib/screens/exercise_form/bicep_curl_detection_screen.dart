import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'analyzers/bicep_curl_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'base_exercise_detection_screen.dart';
import 'package:fitmate/widgets/pose_painter.dart';

class BicepCurlDetectionScreen extends BaseExerciseDetectionScreen {
  const BicepCurlDetectionScreen({Key? key}) 
      : super(key: key, exerciseType: 'Bicep Curl');
  
  @override
  _BicepCurlDetectionScreenState createState() => _BicepCurlDetectionScreenState();
}

class _BicepCurlDetectionScreenState extends BaseExerciseDetectionState<BicepCurlDetectionScreen> {
  late BicepCurlAnalyzer analyzer;
  
  @override
  void initState() {
    // Set preferred camera to front for better self-viewing
    preferredCameraLensDirection = CameraLensDirection.front;
    
    // Create analyzer before calling super.initState() which starts camera
    analyzer = BicepCurlAnalyzer();
    
    super.initState();
  }
  
  @override
  Future<void> processPose(Pose pose) async {
    // Process pose using the bicep curl analyzer
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
        
        // Top status row - Counter and Active Arm
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ExerciseUIComponents.buildStatusRow(
            statusBoxes: [
              // Reps counter
              ExerciseUIComponents.buildStatusBox(
                label: 'REPS',
                value: analyzer.activeArm == "none" ? 
                       'UNK' : '${analyzer.activeArmAnalysis.counter}',
                color: Colors.blue,
                fontSize: 20,
              ),
              
              // Active arm display
              ExerciseUIComponents.buildStatusBox(
                label: 'ARM',
                value: analyzer.activeArm.toUpperCase(),
                color: Colors.blue,
              ),
            ],
          ),
        ),
        
        // Second status row - Elbow and Form status
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: ExerciseUIComponents.buildStatusRow(
            statusBoxes: [
              // Elbow status
              ExerciseUIComponents.buildStatusBox(
                label: 'ELBOW',
                value: analyzer.activeArm == "none" ? 
                       'UNK' : analyzer.activeArmAnalysis.elbowStatus,
                color: analyzer.activeArm == "none" ? 
                       Colors.grey : ExerciseUIComponents.getStatusColor(
                         analyzer.activeArmAnalysis.elbowStatus
                       ),
              ),
              
              // Form status
              ExerciseUIComponents.buildStatusBox(
                label: 'FORM',
                value: analyzer.activeArm == "none" ? 
                       'UNK' : analyzer.activeArmAnalysis.formStatus,
                color: analyzer.activeArm == "none" ? 
                       Colors.grey : ExerciseUIComponents.getStatusColor(
                         analyzer.activeArmAnalysis.formStatus
                       ),
              ),
            ],
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