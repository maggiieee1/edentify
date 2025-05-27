import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class ImagePickerClassify extends StatefulWidget {
  const ImagePickerClassify({super.key});

  @override
  _ImagePickerClassifyState createState() => _ImagePickerClassifyState();
}

class _ImagePickerClassifyState extends State<ImagePickerClassify> {
  List _outputs = [];
  File? _image;
  bool _loading = false;
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    // Initialize Firebase
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
        _endModelProcessing();
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
            ? Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _image == null ? Container() : Image.file(_image!),
                      const SizedBox(height: 20),
                      _outputs.isNotEmpty
                          ? Text(
                              "Classification: ${_outputs[0]["label"].toString().replaceAll(RegExp(r'\d'), '')}",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.05,
                                background: Paint()..color = Colors.white,
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: pickImage,
          backgroundColor: Colors.green[900],
          child: const Icon(Icons.image),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: _image != null && _outputs.isNotEmpty && _firebaseInitialized
                ? () => _saveToFirebase(
                      context,
                      _image!.path,
                      _outputs[0]["label"],
                    )
                : null,
            child: const Text("Save to Firebase"),
          ),
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    File imageFile = File(image.path);

    setState(() {
      _loading = true;
      _image = imageFile;
    });

    classifyImage(imageFile);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 3,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output ?? [];
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_edema.tflite",
      labels: "assets/labels_edema.txt",
    );
  }

  void _endModelProcessing() {
    Tflite.close();
  }

  Future<void> _saveToFirebase(
      BuildContext context, String imagePath, String label) async {
    if (!_firebaseInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase not initialized yet')),
      );
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      // Upload image to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('classification_images/$fileName.jpg');
      await storageRef.putFile(File(imagePath));
      
      // Get the download URL
      String imageUrl = await storageRef.getDownloadURL();

      // Save data to Firestore
      await FirebaseFirestore.instance.collection('classification_results').add({
        'imageUrl': imageUrl,
        'label': label,
        'timestamp': FieldValue.serverTimestamp(),
        'formattedDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firebase successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving to Firebase: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _endModelProcessing();
    super.dispose();
  }
}