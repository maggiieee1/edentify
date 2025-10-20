import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // ✅ Add this package in pubspec.yaml
import 'package:tflite_v2/tflite_v2.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'classification_result_screen.dart';

class ImagePickerClassify extends StatefulWidget {
  const ImagePickerClassify({super.key});

  @override
  _ImagePickerClassifyState createState() => _ImagePickerClassifyState();
}

class _ImagePickerClassifyState extends State<ImagePickerClassify> {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Tflite.close();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal[700],
          centerTitle: true,
          title: Text(
            "Edentify",
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: _image == null
                    ? const Text("No image selected")
                    : Image.file(_image!),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickAndClassifyImage,
          backgroundColor: Colors.teal[900],
          child: const Icon(Icons.image),
        ),
      ),
    );
  }

  Future<void> _pickAndClassifyImage() async {
    final picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    File imageFile = await _convertToJpgIfNeeded(File(image.path));

    setState(() {
      _loading = true;
      _image = imageFile;
    });

    try {
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
      setState(() {
        _loading = false;
      });
    }
  }

  // ✅ Converts HEIF/HEIC files to JPG before classification
  Future<File> _convertToJpgIfNeeded(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'heic' || ext == 'heif') {
      try {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final jpgPath = file.path.replaceAll(RegExp(r'\.heic|\.heif', caseSensitive: false), '.jpg');
          final jpgFile = File(jpgPath)
            ..writeAsBytesSync(img.encodeJpg(decoded, quality: 95));
          print('✅ Converted HEIF to JPG: ${jpgFile.path}');
          return jpgFile;
        } else {
          print('⚠️ Failed to decode HEIF, using original');
          return file;
        }
      } catch (e) {
        print('Error converting HEIF to JPG: $e');
        return file;
      }
    }
    return file;
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}