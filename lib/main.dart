// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: GlaucomaDetectionPage(),
//     );
//   }
// }
//
// class GlaucomaDetectionPage extends StatefulWidget {
//   @override
//   _GlaucomaDetectionPageState createState() => _GlaucomaDetectionPageState();
// }
//
// class _GlaucomaDetectionPageState extends State<GlaucomaDetectionPage> {
//   Interpreter? _interpreter;
//   img.Image? _originalImage;
//   String? originalImagePath;
//   img.Image? _maskImage;
//   String _cdrResult = '';
//   Color _cdrResultColor = Colors.green;
//   double _opacity = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadModel();
//   }
//
//   Future<void> _loadModel() async {
//     _interpreter = await Interpreter.fromAsset('assets/unet_model.tflite');
//     setState(() {});
//   }
//
//   Future<void> _processImage(String imagePath) async {
//
//     final image = img.decodeImage(await File(imagePath).readAsBytes())!;
//     _originalImage = img.copyResize(image, width: 128, height: 128);
//     final input = _preprocessImage(_originalImage!);
//
//     final output = List.filled(128 * 128 * 3, 0.0).reshape([1, 128, 128, 3]); // Adjust output shape
//     _interpreter!.run(input, output);
//
//     final mask = _postProcessOutput(output);
//     _maskImage = mask;
//
//     final cdr = _calculateCDR(mask);
//     _cdrResult = 'Cup Area: ${cdr['cupArea']}\nDisc Area: ${cdr['discArea']}\nCDR: ${cdr['cdr'].toStringAsFixed(4)}';
//
//     _originalImage = null;
//     if (cdr['cdr'] > 0.4) {
//       _cdrResult += '\nGlaucoma Positive. Contact a doctor.';
//       _cdrResultColor = Colors.red;
//     } else {
//       _cdrResult += '\nGlaucoma Negative. No need to contact a doctor.';
//       _cdrResultColor = Colors.green;
//     }
//
//     setState(() {
//       _opacity = 1.0;
//     });
//   }
//
//   List<List<List<List<double>>>> _preprocessImage(img.Image image) {
//     final input = List.generate(128, (i) => List.generate(128, (j) {
//       final pixel = image.getPixel(i, j);
//       return [
//         img.getRed(pixel) / 255.0,
//         img.getGreen(pixel) / 255.0,
//         img.getBlue(pixel) / 255.0,
//       ];
//     }));
//     return [input];
//   }
//
//   img.Image _postProcessOutput(List output) {
//     final mask = img.Image(128, 128);
//     for (int i = 0; i < 128; i++) {
//       for (int j = 0; j < 128; j++) {
//         // Assuming the model outputs a three-channel mask (RGB)
//         int r = (output[0][i][j][0] * 255).toInt();
//         int g = (output[0][i][j][1] * 255).toInt();
//         int b = (output[0][i][j][2] * 255).toInt();
//         mask.setPixel(i, j, img.getColor(r, g, b));
//       }
//     }
//     return mask;
//   }
//
//   Map<String, dynamic> _calculateCDR(img.Image mask) {
//     int cupArea = 0;
//     int discArea = 0;
//
//     for (int i = 0; i < 128; i++) {
//       for (int j = 0; j < 128; j++) {
//         final pixel = mask.getPixel(i, j);
//         // Check the color of the pixel to determine the area
//         final r = img.getRed(pixel);
//         final g = img.getGreen(pixel);
//         final b = img.getBlue(pixel);
//
//         // Assuming blue represents the cup area and red represents the disc area
//         if (b > 200 && r < 50 && g < 50) {
//           cupArea++;
//         } else if (r > 200 && g < 50 && b < 50) {
//           discArea++;
//         }
//       }
//     }
//     discArea = discArea + cupArea;
//
//     final cdr = discArea == 0 ? 0 : cupArea / discArea;
//     return {'cupArea': cupArea, 'discArea': discArea, 'cdr': cdr};
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Glaucoma Detection'),
//         backgroundColor: Colors.teal,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               if (_originalImage != null)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Center(child: Image.memory(Uint8List.fromList(img.encodeJpg(_originalImage!)))),
//                 ),
//               if (_maskImage != null)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: AnimatedOpacity(
//                     opacity: _opacity,
//                     duration: Duration(seconds: 1),
//                     child: Image.memory(Uint8List.fromList(img.encodeJpg(_maskImage!))),
//                   ),
//                 ),
//               if(_maskImage!=null)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: AnimatedOpacity(
//                     opacity: _opacity,
//                     duration: Duration(seconds: 1),
//                     child: Text(
//                       _cdrResult,
//                       style: TextStyle(fontSize: 18, color: _cdrResultColor),
//                     ),
//                   ),
//                 ),
//
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ElevatedButton.icon(
//               onPressed: () async {
//                 originalImagePath = await _pickImage();
//                 if (originalImagePath!=null) {
//                   _originalImage = img.decodeImage(await File(originalImagePath!).readAsBytes());
//                   setState(() {});
//                 }
//               },
//               icon: Icon(Icons.photo_library),
//               label: Text('Upload Image'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.teal,
//                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//             ),
//             SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: () async {
//                 if (_originalImage != null) {
//                   await _processImage(originalImagePath!);
//                 }
//               },
//               icon: Icon(Icons.visibility),
//               label: Text('Process Image'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.teal,
//                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<String> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if(pickedFile!=null){
//       _maskImage = null;
//     }
//     return pickedFile?.path ?? '';
//   }
// }
//
//

import 'package:flutter/material.dart';
import 'package:gluacoma_detection/HomeScreen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}





