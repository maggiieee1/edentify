import 'package:flutter/material.dart';

class EdemaClassifierScreen extends StatelessWidget {
  const EdemaClassifierScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tealColor = const Color(0xFF17A38B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edema Classifier'),
        backgroundColor: tealColor,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/classifyCamera');
                  },
                  label: const Text('Take a Photo'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/imagePickerClassify');
                  },
                  label: const Text('Upload an Image'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}