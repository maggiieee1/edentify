import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'classification_result_screen.dart';

class ClassifyCamera extends StatefulWidget {
  const ClassifyCamera({super.key});

  @override
  _ClassifyCameraState createState() => _ClassifyCameraState();
}

class _ClassifyCameraState extends State<ClassifyCamera> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  bool _loading = false;
  bool _firebaseInitialized = false;
  bool _isFlashOn = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loading = true;

    _initializeFirebase().then((_) {
      setState(() {
        _firebaseInitialized = true;
      });
    });

    availableCameras().then((cameras) {
      _cameras = cameras;
      _camera = cameras.first;
      _initializeCamera();
    });

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print("Firebase initialized successfully");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  void _initializeCamera() {
    _cameraController = CameraController(
      _camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _cameraController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _toggleFlash() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      print("Error toggling flash: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Tflite.close();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF008080), // Teal color
          centerTitle: true,
          title: Text(
            "Edentify",
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: _isFlashOn ? Colors.yellow : Colors.white,
              ),
              tooltip: _isFlashOn ? 'Flash On' : 'Flash Off',
            ),
          ],
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  alignment: Alignment.center,
                  children: [
                    _cameraController.value.isInitialized
                        ? CameraPreview(_cameraController)
                        : const Center(child: CircularProgressIndicator()),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: _captureAndClassifyImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008080),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Capture and Classify",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _captureAndClassifyImage() async {
    try {
      final image = await _cameraController.takePicture();
      File imageFile = File(image.path);

      setState(() {
        _image = imageFile;
        _loading = true;
      });

      var output = await Tflite.runModelOnImage(
        path: imageFile.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      setState(() {
        _loading = false;
      });

      if (output != null && output.isNotEmpty) {
        final label =
            output[0]["label"].toString().replaceAll(RegExp(r'\d'), '').trim();
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid ?? 'unknown_user';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ClassificationResultScreen(
                  imagePath: imageFile.path,
                  label: label,
                  userId: userId,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No classification result')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    Tflite.close();
    super.dispose();
  }
}
