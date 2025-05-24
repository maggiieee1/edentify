import 'dart:io';
import 'dart:async';
import 'package:tflite_v2/tflite_v2.dart';

class EdemaModelService {
  EdemaModelService._privateConstructor();
  static final EdemaModelService instance = EdemaModelService._privateConstructor();

  bool _isModelLoaded = false;
  bool _isRunning = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration debounceDuration = Duration(milliseconds: 800);

  /// Loads the TFLite model and label file
  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    await Tflite.close(); // Clear previous model if any
    final result = await Tflite.loadModel(
      model: 'assets/model_edema.tflite',
      labels: 'assets/labels_edema.txt',
    );

    if (result == null) {
      print("❌ Failed to load Edema model.");
    } else {
      print("✅ Edema model loaded: $result");
      _isModelLoaded = true;
    }
  }

  /// Runs inference on the provided image file and returns the top label
  Future<String?> classifyImage(File image) async {
    final now = DateTime.now();

    if (!_isModelLoaded) {
      print("⚠️ Model not loaded yet.");
      return null;
    }

    if (_isRunning) {
      print("⚠️ Inference already running. Skipping request.");
      return null;
    }

    if (now.difference(_lastInferenceTime) < debounceDuration) {
      print("⏳ Debounced inference to avoid rapid repeats.");
      return null;
    }

    _isRunning = true;
    _lastInferenceTime = now;

    try {
      final recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 4,
        threshold: 0.3,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        final label = recognitions[0]['label'];
        print("✅ Inference result: $label");
        return label;
      } else {
        print("ℹ️ No recognition results.");
        return null;
      }
    } catch (e) {
      print("❌ Error during classification: $e");
      return null;
    } finally {
      _isRunning = false;
    }
  }

  /// Frees model resources
  Future<void> disposeModel() async {
    await Tflite.close();
    _isModelLoaded = false;
    _isRunning = false;
    print("🧹 Edema model resources released.");
  }
}