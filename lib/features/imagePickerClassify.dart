import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img; // ❌ REMOVE THIS (Too slow)
import 'package:flutter_image_compress/flutter_image_compress.dart'; // ✅ ADD THIS
import 'package:tflite_v2/tflite_v2.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Needed to get temp directory
import 'classification_result_screen.dart';

class ImagePickerClassify extends StatefulWidget {
  const ImagePickerClassify({super.key});

  @override
  _ImagePickerClassifyState createState() => _ImagePickerClassifyState();
}

class _ImagePickerClassifyState extends State<ImagePickerClassify> {
  bool _loading = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loading = true;

    _initializeFirebase();

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Optional: Tflite.close(); usually handled in dispose
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
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                  child:
                      _image == null
                          ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 100,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Select an image from gallery",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
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
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _loading = true;
    });

    try {
      // ⚡️ OPTIMIZATION: Compress & Convert to JPG immediately
      // This handles HEIC conversion automatically and resizes the image
      // so TFLite doesn't crash on large inputs.
      File optimizedFile = await _compressAndConvertFile(File(pickedFile.path));

      setState(() {
        _image = optimizedFile;
      });

      // Run TFLite on the OPTIMIZED file (much faster)
      var output = await Tflite.runModelOnImage(
        path: optimizedFile.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      setState(() {
        _loading = false;
      });

      if (output != null && output.isNotEmpty) {
        // Clean label text
        final label = output[0]["label"].toString().replaceAll(
          RegExp(r'\d'),
          '',
        );

        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid ?? 'unknown_user';

        if (!mounted) return; // 🛡️ Safety check before navigation

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ClassificationResultScreen(
                  imagePath: optimizedFile.path, // Pass the optimized path
                  label: label,
                  userId: userId,
                ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No classification result')),
        );
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // 🚀 FAST Native Compression & Conversion
  Future<File> _compressAndConvertFile(File file) async {
    final lastIndex = file.path.lastIndexOf(RegExp(r'.jp'));
    final splitted = file.path.substring(0, (lastIndex));
    final outPath = "${splitted}_out.jpg";

    // If it's already a reasonable size/format, this library is smart enough
    // to handle it efficiently.
    // 1080px is plenty for TFLite and saves memory.
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
    );

    if (result == null) {
      return file; // Fallback to original if compression fails
    }

    return File(result.path);
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
