import 'package:flutter/services.dart';
import 'dart:io';
import 'package:tflite_v2/tflite_v2.dart';

class ModelService {
  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: 'assets/model_edema.tflite',
      );
    } on PlatformException {
      print('Failed to load model');
    }
  }

  // Run inference on an image
  Future<String> runInference(File imageFile) async {
    var prediction = await Tflite.runModelOnImage(
      path: imageFile.path,
      numResults: 3, // Number of results to return
      threshold: 0.5, // Confidence threshold
      asynch: true,
    );

    if (prediction != null) {
      // Process prediction here (e.g., retrieve predicted class and confidence)
      String predictedClass = prediction[0]['label'];
      double confidence = prediction[0]['confidence'];
      return 'Predicted Class: $predictedClass, Confidence: $confidence';
    } else {
      return 'Prediction failed';
    }
  }

  // Dispose the model when done
  Future<void> dispose() async {
    await Tflite.close();
  }
}