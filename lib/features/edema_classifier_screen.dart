import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'classification_result_screen.dart';

class EdemaClassifierScreen extends StatefulWidget {
  final String userId;

  const EdemaClassifierScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<EdemaClassifierScreen> createState() => _EdemaClassifierScreenState();
}

class _EdemaClassifierScreenState extends State<EdemaClassifierScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _loading = false;
  File? _image;
  String? _predictedLabel;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() => _isCameraReady = true);
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_edema.tflite",
      labels: "assets/labels_edema.txt",
    );
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final picture = await _controller!.takePicture();
      final file = File(picture.path);
      setState(() {
        _image = file;
      });
      await _classifyImage(file);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _image = file;
      });
      await _classifyImage(file);
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    setState(() => _loading = true);

    try {
      final output = await Tflite.runModelOnImage(
        path: imageFile.path,
        numResults: 4,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      setState(() => _loading = false);

      if (output != null && output.isNotEmpty) {
        final label = output[0]["label"].toString().replaceAll(RegExp(r'\d'), '');
        setState(() {
          _predictedLabel = label;
        });

        // ✅ Navigate to ClassificationResultScreen for Save/Retake
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClassificationResultScreen(
              imagePath: imageFile.path,
              label: label,
              userId: widget.userId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No classification result")),
        );
      }
    } catch (e) {
      debugPrint("Classification error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isCameraReady
              ? CameraPreview(_controller!)
              : const Center(child: CircularProgressIndicator()),

          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    iconSize: 32,
                    onPressed: _pickImage,
                  ),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}