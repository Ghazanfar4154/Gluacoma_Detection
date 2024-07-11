import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class GlaucomaDetectionPage extends StatefulWidget {
  GlaucomaDetectionPage(
      {required this.originalImagePath,
        required this.originalImage,
        required this.interpreter});

  img.Image? originalImage;
  String? originalImagePath;
  Interpreter? interpreter;

  @override
  _GlaucomaDetectionPageState createState() => _GlaucomaDetectionPageState();
}

class _GlaucomaDetectionPageState extends State<GlaucomaDetectionPage> {
  img.Image? _maskImage;
  img.Image? _deskMaskImage;
  img.Image? _cupMaskImage;

  String _cdrResult = '';
  Color _cdrResultColor = Colors.green;
  double _opacity = 0.0;
  var completeCDR;

  Future<void> _processImage(String imagePath) async {
    final image = img.decodeImage(await File(imagePath).readAsBytes())!;
    widget.originalImage = img.copyResize(image, width: 128, height: 128);
    final input = _preprocessImage(widget.originalImage!);

    final output = List.filled(128 * 128 * 3, 0.0).reshape([1, 128, 128, 3]);
    widget.interpreter!.run(input, output);

    final mask = _postProcessOutput(output);
    _maskImage = mask;
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final input = List.generate(128, (i) => List.generate(128, (j) {
      final pixel = image.getPixel(i, j);
      return [
        img.getRed(pixel) / 255.0,
        img.getGreen(pixel) / 255.0,
        img.getBlue(pixel) / 255.0,
      ];
    }));
    return [input];
  }

  img.Image _postProcessOutput(List output) {
    int cupArea = 0;
    int discArea = 0;
    final mask = img.Image(128, 128);
    _deskMaskImage = img.Image(128, 128);
    _cupMaskImage = img.Image(128, 128);

    for (int i = 0; i < 128; i++) {
      for (int j = 0; j < 128; j++) {
        int r = (output[0][i][j][0] * 255).toInt();
        int g = (output[0][i][j][1] * 255).toInt();
        int b = (output[0][i][j][2] * 255).toInt();
        // If the color is green, change it to black
        if (r < 50 && g > 200 && b < 50) {
          mask.setPixel(i, j, img.getColor(128, 128, 128));
          _deskMaskImage!.setPixel(i, j, img.getColor(128, 128, 128));
          _cupMaskImage!.setPixel(i, j, img.getColor(0, 0, 0));
          discArea++;
        }
        // If the color is blue, change it to white
        else if (r < 50 && g < 50 && b > 200) {
          mask.setPixel(i, j, img.getColor(255, 255, 255));
          _cupMaskImage!.setPixel(i, j, img.getColor(255, 255, 255));
          _deskMaskImage!.setPixel(i, j, img.getColor(128, 128, 128));
          cupArea++;
        }
        // If the color is red, change it to red
        else if (r > 200 && g < 50 && b < 50) {
          mask.setPixel(i, j, img.getColor(0, 0, 0));
          _deskMaskImage!.setPixel(i, j, img.getColor(0, 0, 0));
          _cupMaskImage!.setPixel(i, j, img.getColor(0, 0, 0));
        } else if (r > g) {
          mask.setPixel(i, j, img.getColor(0, 0, 0));
          _deskMaskImage!.setPixel(i, j, img.getColor(0, 0, 0));
          _cupMaskImage!.setPixel(i, j, img.getColor(0, 0, 0));
        }
        // Otherwise, keep the original color
        else {
          mask.setPixel(i, j, img.getColor(128, 128, 128));
          _deskMaskImage!.setPixel(i, j, img.getColor(128, 128, 128));
          _cupMaskImage!.setPixel(i, j, img.getColor(0, 0, 0));
        }
      }
    }

    final cdrValue = discArea == 0 ? 0 : cupArea / discArea;
    completeCDR = {'cupArea': cupArea, 'discArea': discArea, 'cdr': cdrValue};

    final cdr = completeCDR;
    _cdrResult = 'Cup Area: ${cdr['cupArea']}\nDisc Area: ${cdr['discArea']}\nCDR: ${cdr['cdr'].toStringAsFixed(4)}';

    if (cdr['cdr'] > 0.4) {
      _cdrResult += '\nGlaucoma Positive. Contact a doctor.';
      _cdrResultColor = Colors.red;
    } else {
      _cdrResult += '\nGlaucoma Negative. No need to contact a doctor.';
      _cdrResultColor = Colors.green;
    }

    setState(() {
      _opacity = 1.0;
    });
    return mask;
  }

  @override
  void initState() {
    super.initState();
    _processImage(widget.originalImagePath!).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Glaucoma Results'),
        backgroundColor: Colors.teal,
      ),
      body:_cdrResult==''?CircularProgressIndicator(): SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  if (widget.originalImage != null)
                    _buildImageCard('Original Image',
                        img.encodeJpg(widget.originalImage!)),
                  if (_maskImage != null)
                    _buildImageCard(
                        'Mask Image', img.encodeJpg(_maskImage!)),
                  if (_deskMaskImage != null)
                    _buildImageCard(
                        'Desk Mask Image', img.encodeJpg(_deskMaskImage!)),
                  if (_cupMaskImage != null)
                    _buildImageCard(
                        'Cup Mask Image', img.encodeJpg(_cupMaskImage!)),
                ],
              ),
              SizedBox(height: 20),
              if (_maskImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: Duration(seconds: 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cdrResultColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _cdrResultColor,
                          width: 2,
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Results',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _cdrResultColor,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _cdrResult,
                            style: TextStyle(fontSize: 18, color: _cdrResultColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, List<int> imageData) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              child: Image.memory(
                Uint8List.fromList(imageData),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}