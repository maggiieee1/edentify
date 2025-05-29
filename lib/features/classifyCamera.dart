import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'classification_result_screen.dart'; // Import the new screen

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
    _cameraController = CameraController(_camera, ResolutionPreset.medium);
    _cameraController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Tflite.close();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          centerTitle: true,
          title: Text(
            "Edentify",
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  _cameraController.value.isInitialized
                      ? CameraPreview(_cameraController)
                      : Container(),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _captureAndClassifyImage,
                      child: const Text("Capture and Classify"),
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
        numResults: 3,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      setState(() {
        _loading = false;
      });

      if (output != null && output.isNotEmpty) {
        final label = output[0]["label"].toString().replaceAll(RegExp(r'\d'), '');
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid ?? 'unknown_user';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassificationResultScreen(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_edema.tflite",
      labels: "assets/labels_edema.txt",
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    Tflite.close();
    super.dispose();
  }
}