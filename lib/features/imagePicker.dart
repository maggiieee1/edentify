import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/model_service.dart'; // Import the model service

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  late File _image;
  String _result = '';
  final ImagePicker _picker = ImagePicker();
  final ModelService _modelService = ModelService();

  @override
  void initState() {
    super.initState();
    _modelService.loadModel(); // Load the model when the app starts
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile!.path);
    });

    // Perform inference
    String result = await _modelService.runInference(_image);
    setState(() {
      _result = result; // Show the result on screen
    });
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edema Model Inference'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? const Text('No image selected.') : Image.file(_image),
            const SizedBox(height: 20),
            Text(_result), // Display the prediction result
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}