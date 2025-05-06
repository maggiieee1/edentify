import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as img;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;
  String _resultText = '';
  late Interpreter _interpreter;
  late List<String> _labels;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('optimized_model.tflite');
      final labelsData = await File('assets/labels.txt').readAsLines();
      _labels = labelsData;
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });
      await _classifyImage(File(pickedFile.path));
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    final rawImage = imageFile.readAsBytesSync();
    final decodedImage = img.decodeImage(rawImage);
    final resizedImage = img.copyResize(decodedImage!, width: 224, height: 224);

    final input = imageToByteListFloat32(resizedImage, 224);
    var output = List.filled(_labels.length, 0).reshape([1, _labels.length]);

    _interpreter.run(input, output);

    final resultIndex = output[0].indexWhere((e) => e == output[0].reduce((a, b) => a > b ? a : b));

    setState(() {
      _isLoading = false;
      _resultText = _labels[resultIndex];
    });
  }

  TensorImage imageToByteListFloat32(img.Image image, int inputSize) {
    final tensorImage = TensorImage.fromImage(image);
    final processor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .add(NormalizeOp(127.5, 127.5))
        .build();
    return processor.process(tensorImage);
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Scan Edema', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset('assets/logo.png'),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (_image != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No Image Selected'),
              ),
            ),
          const SizedBox(height: 20),
          if (_resultText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Prediction: $_resultText', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.upload, color: Color(0xFF00A18D), size: 32),
                onPressed: () => _getImage(ImageSource.gallery),
              ),
              GestureDetector(
                onTap: () => _getImage(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00A18D),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ],
      ),
    );
  }
}
