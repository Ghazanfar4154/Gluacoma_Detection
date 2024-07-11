import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'Gluacoma_Detection_Page.dart';
import 'Instruction_Page.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  img.Image? _originalImage;
  String? originalImagePath;
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/unet_model.tflite');
    setState(() {});
  }

  Future<String> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile?.path ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eye Health Assistant'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: MediaQuery.of(context).size.width * 0.1,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InstructionPage()),
                );
              },
              child: CircularButton(
                text: 'Instructions',
                icon: Icons.info_outline,
                size: MediaQuery.of(context).size.width * 0.3,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width * 0.57,
            child: GestureDetector(
              onTap: () {
                if (originalImagePath == null || originalImagePath == '') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Select image first")),
                  );
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return GlaucomaDetectionPage(
                        originalImagePath: originalImagePath,
                        originalImage: _originalImage,
                        interpreter: _interpreter);
                  }));
                }
              },
              child: CircularButton(
                text: 'Process Image',
                icon: Icons.visibility,
                size: MediaQuery.of(context).size.width * 0.42,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * -0.05,
            child: GestureDetector(
              onTap: () async {
                originalImagePath = await _pickImage();
                if (originalImagePath != null) {
                  _originalImage =
                      img.decodeImage(await File(originalImagePath!).readAsBytes());
                  setState(() {});
                }
              },
              child: CircularButton(
                text: 'Upload photos',
                icon: Icons.photo,
                size: MediaQuery.of(context).size.width * 0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final double size;

  CircularButton({required this.text, required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.green, Colors.greenAccent],
          center: Alignment(-0.5, -0.5),
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: size * 0.35,
            color: Colors.white,
          ),
          SizedBox(height: size * 0.05),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.12,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 5,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
