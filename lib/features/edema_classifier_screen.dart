import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/model_service.dart';
import 'classification_result_screen.dart';

class EdemaClassifierScreen extends StatefulWidget {
  final String userId;

  const EdemaClassifierScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<EdemaClassifierScreen> createState() => _EdemaClassifierScreenState();
}

class _EdemaClassifierScreenState extends State<EdemaClassifierScreen> {
  File? _selectedImage;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    EdemaModelService.instance.loadModel();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    if (await Permission.camera.isGranted) {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera permission denied')));
    }
  }

  Future<void> _takePhoto() async {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized)
      return;

    final directory = await getTemporaryDirectory();
    final imagePath = p.join(
      directory.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    try {
      final file = await _cameraController!.takePicture();
      final imageFile = File(file.path);
      _handleImage(imageFile);
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      _handleImage(imageFile);
    }
  }

  bool _isClassifying = false;

  Future<void> _handleImage(File imageFile) async {
  if (_isClassifying) return;

  setState(() {
    _selectedImage = imageFile;
    _isClassifying = true;
  });

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final result = await EdemaModelService.instance.classifyImage(imageFile);
    Navigator.pop(context); // remove loading spinner
    _navigateToResultScreen(imageFile, result);
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to classify image: $e')));
  } finally {
    setState(() {
      _isClassifying = false;
    });
  }
}

  void _retakeFunction() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _navigateToResultScreen(File image, String? result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClassificationResultScreen(
              label: result ?? 'Unknown',
              imageFile: image,
              onRetake: _retakeFunction,
              userId: widget.userId,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    EdemaModelService.instance.disposeModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tealColor = const Color(0xFF17A38B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edema Classifier'),
        backgroundColor: tealColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else if (_isCameraInitialized && _cameraController != null)
                Container(
                  width: double.infinity,
                  height:
                      MediaQuery.of(context).size.height *
                      0.6, // take up 60% of screen
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tealColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
