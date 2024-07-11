import 'package:flutter/material.dart';

class InstructionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('How to Use the App'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 20),
              InstructionStep(
                stepNumber: 1,
                instruction:
                'Upload an eye image by tapping the "Upload photos" button. Make sure the image is clear and focused.',
              ),
              InstructionStep(
                stepNumber: 2,
                instruction:
                'After uploading, the image will be displayed on the screen. Tap the "Process Image" button to start the glaucoma detection process.',
              ),
              InstructionStep(
                stepNumber: 3,
                instruction:
                'The app will process the image and display the results, including the Cup-to-Disc Ratio (CDR).',
              ),
              InstructionStep(
                stepNumber: 4,
                instruction:
                'Based on the CDR value, the app will indicate whether you are at risk of glaucoma. Follow the recommendations displayed.',
              ),
              SizedBox(height: 20),
              Text(
                'Note:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'This app is not a substitute for professional medical advice. If you suspect you have glaucoma, please consult a healthcare professional.',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructionStep extends StatelessWidget {
  final int stepNumber;
  final String instruction;

  InstructionStep({required this.stepNumber, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: Text(
              '$stepNumber',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}