import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'analyzers/plank_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'package:fitmate/widgets/pose_painter.dart';
import 'package:flutter/services.dart';
import 'base_exercise_detection_screen.dart';

class PlankDetectionScreen extends BaseExerciseDetectionScreen {
  const PlankDetectionScreen({Key? key}) 
      : super(key: key, exerciseType: 'Plank');
 

  @override
  _PlankDetectionScreenState createState() => _PlankDetectionScreenState();
}

class _PlankDetectionScreenState extends State<PlankDetectionScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  Pose? _currentPose;
  late PlankAnalyzer _analyzer;
  
  @override
  void initState() {
    super.initState();
    _analyzer = PlankAnalyzer();
    _initializeDetector();
    _initializeCamera();
  }
  
  void _initializeDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    // Select front camera
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    // Initialize with lower resolution for better performance
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _cameraController!.initialize();
      
      // Start image stream once camera is initialized
      _cameraController!.startImageStream(_processCameraImage);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      final camera = _cameraController!.description;
      
      final inputImage = _convertCameraImageToInputImage(image, camera);
      if (inputImage == null) return;
      
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        final pose = poses.first;
        
        // Process the pose using the plank analyzer
        _analyzer.analyzePose(pose);
        
        if (mounted) {
          setState(() {
            _currentPose = pose;
          });
        }
      }
    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  InputImage? _convertCameraImageToInputImage(CameraImage image, CameraDescription camera) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Create InputImage
      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: _getInputImageRotation(camera.sensorOrientation),
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      
      return InputImage.fromBytes(
        bytes: bytes, 
        metadata: inputImageData,
      );
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }
  
  InputImageRotation _getInputImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
    
  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseType} Form Analysis'),
      ),
      body: Stack(
        children: [
          // Camera Preview with proper aspect ratio
          Container(
            width: double.infinity,
            height: double.infinity,
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          
          // Pose overlay when pose is detected
          if (_currentPose != null)
            CustomPaint(
              painter: PosePainter(
                pose: _currentPose!,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                isFrontCamera: true,
              ),
              size: Size.infinite,
            ),
          
          // Top status row - Duration and Form status
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ExerciseUIComponents.buildStatusRow(
              statusBoxes: [
                // Duration counter
                ExerciseUIComponents.buildStatusBox(
                  label: 'DURATION',
                  value: _formatDuration(_analyzer.currentDuration),
                  color: Colors.blue,
                  fontSize: 20,
                ),
                ExerciseUIComponents.buildStatusBox(
                  label: 'BACK',
                  value: _analyzer.backStatus,
                  color: ExerciseUIComponents.getStatusColor(_analyzer.backStatus),
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
                  feedbackText: _analyzer.getFormFeedback(),
                ),
                
                // Position instruction
                ExerciseUIComponents.buildInstructionsBox(
                  instructionsText: _analyzer.getPositionInstructions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}