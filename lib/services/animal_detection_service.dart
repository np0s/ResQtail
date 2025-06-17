import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AnimalDetectionService {
  static const String _modelPath = 'assets/models/mobilenet_v1_1.0_224_quant.tflite';
  static const String _labelsPath = 'assets/models/labels_mobilenet_quant_v1_224.txt';
  static const int _inputSize = 224;

  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      final labelsString = await rootBundle.loadString(_labelsPath);
      _labels = labelsString.split('\n');
    } catch (e) {
      debugPrint('Error initializing animal detection: $e');
    }
  }

  Future<String?> detectAnimal(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      await initialize();
      if (_interpreter == null || _labels == null) {
        return null;
      }
    }

    try {
      // Load and preprocess the image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );

      // Convert image to uint8 values (0-255)
      final inputBuffer = Uint8List(_inputSize * _inputSize * 3);
      int bufferIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          final r = img.getRed(pixel);
          final g = img.getGreen(pixel);
          final b = img.getBlue(pixel);
          inputBuffer[bufferIndex++] = r;
          inputBuffer[bufferIndex++] = g;
          inputBuffer[bufferIndex++] = b;
        }
      }

      // The model expects shape [1, 224, 224, 3]
      final input = inputBuffer.reshape([1, _inputSize, _inputSize, 3]);
      final output = List.filled(1001, 0.0).reshape([1, 1001]);

      // Run inference
      _interpreter!.run(input, output);

      // Get the highest probability class
      final result = output[0] as List<int>;
      int maxScore = result[0];
      int maxIndex = 0;
      for (int i = 1; i < result.length; i++) {
        if (result[i] > maxScore) {
          maxScore = result[i];
          maxIndex = i;
        }
      }

      // Return the detected animal if confidence is high enough
      if (maxScore > 0.5) {
        return _labels![maxIndex];
      }

      return null;
    } catch (e) {
      debugPrint('Error detecting animal: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
} 