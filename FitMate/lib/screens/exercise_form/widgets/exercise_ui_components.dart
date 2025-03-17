import 'package:flutter/material.dart';

/// Common UI components for exercise screens
class ExerciseUIComponents {
  /// Status box showing a label and value with a colored background
  static Widget buildStatusBox({
    required String label,
    required String value,
    required Color color,
    double fontSize = 16,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Status row with multiple status boxes
  static Widget buildStatusRow({
    required List<Widget> statusBoxes,
    double height = 80,
  }) {
    return Container(
      height: height,
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: statusBoxes.map((widget) => Expanded(child: widget)).toList(),
      ),
    );
  }
  
  /// Feedback box at bottom of screen
  static Widget buildFeedbackBox({
    required String feedbackText,
    Color backgroundColor = Colors.black,
    double opacity = 0.7,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        feedbackText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Instructions box at bottom of screen
  static Widget buildInstructionsBox({
    required String instructionsText,
    Color backgroundColor = Colors.blue,
    double opacity = 0.7,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        instructionsText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  static Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'good':
    case 'correct':
      return Colors.green;
    case 'too narrow':
    case 'too far out': 
    case 'too wide':
    case 'half rep':
    case 'too high':  
    case 'too low':   
    case 'misaligned': 
      return Colors.red;
    case 'curl higher':
    case 'extend fully':
    case 'warning':
    case 'needs correction': 
      return Colors.orange;
    case 'unk':
    default:
      return Colors.grey;
  }
}
}