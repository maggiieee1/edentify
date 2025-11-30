import 'package:flutter/services.dart';
import 'dart:io';
import 'package:tflite_v2/tflite_v2.dart';

class ModelService {
  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(model: 'assets/model_edema.tflite');
    } on PlatformException {
      print('Failed to load model');
    }
  }

  Future<String> runInference(File imageFile) async {
    var prediction = await Tflite.runModelOnImage(
      path: imageFile.path,
      numResults: 3,
      threshold: 0.5,
      asynch: true,
    );

    if (prediction != null) {
      String predictedClass = prediction[0]['label'];
      double confidence = prediction[0]['confidence'];
      return 'Predicted Class: $predictedClass, Confidence: $confidence';
    } else {
      return 'Prediction failed';
    }
  }

  Future<void> dispose() async {
    await Tflite.close();
  }
}
