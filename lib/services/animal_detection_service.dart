import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum DetectionAPI {
  huggingFace,
  imagga,
}

class AnimalDetectionService {
  static const double _confidenceThreshold = 0.5;
  static const DetectionAPI _currentAPI = DetectionAPI.huggingFace; // Change this to switch APIs
  
  // Animal categories we're interested in
  final Set<String> _animalCategories = {
    'dog', 'cat', 'bird', 'cow', 'horse', 'sheep', 'pig',
    'duck', 'rabbit', 'mouse', 'rat', 'squirrel', 'deer',
    'bear', 'wolf', 'fox', 'tiger', 'lion', 'elephant'
  };

  // Initialize method - no longer needed for API but kept for compatibility
  Future<void> initialize() async {
    // Nothing to initialize for API-based implementation
    debugPrint('AnimalDetectionService initialized with ${_currentAPI.name}');
  }

  // Dispose method - no longer needed for API but kept for compatibility
  void dispose() {
    // Nothing to dispose for API-based implementation
    debugPrint('AnimalDetectionService disposed');
  }

  Future<String?> detectAnimal(File imageFile) async {
    switch (_currentAPI) {
      case DetectionAPI.huggingFace:
        return _detectAnimalWithHuggingFace(imageFile);
      case DetectionAPI.imagga:
        return _detectAnimalWithImagga(imageFile);
    }
  }

  Future<String?> _detectAnimalWithHuggingFace(File imageFile) async {
    try {
      final apiKey = dotenv.env['HUGGINGFACE_API_KEY'];
      if (apiKey == null) {
        debugPrint('Hugging Face API key not found in .env');
        return null;
      }

      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Make API request to Hugging Face
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/google/vit-base-patch16-224'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'inputs': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> predictions = json.decode(response.body);
        
        debugPrint('Top 5 predictions:');
        for (int i = 0; i < 5 && i < predictions.length; i++) {
          final prediction = predictions[i];
          debugPrint('$i: ${prediction['label']} (confidence: ${prediction['score']})');
        }

        // Check if any of the predictions match our animal categories
        for (final prediction in predictions) {
          final label = prediction['label'].toString().toLowerCase();
          final confidence = prediction['score'] as double;

          // Check if the label contains any of our animal categories
          for (final animal in _animalCategories) {
            if (label.contains(animal)) {
              debugPrint('Found animal: $animal (from $label) with confidence $confidence');
              if (confidence >= _confidenceThreshold) {
                return animal;
              }
            }
          }
        }

        return 'unknown';
      } else {
        debugPrint('Hugging Face API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error detecting animal with Hugging Face: $e');
      return null;
    }
  }

  Future<String?> _detectAnimalWithImagga(File imageFile) async {
    try {
      final apiKey = dotenv.env['IMAGGA_API_KEY'];
      final apiSecret = dotenv.env['IMAGGA_API_SECRET'];
      if (apiKey == null || apiSecret == null) {
        debugPrint('Imagga API credentials not found in .env');
        return null;
      }

      // Upload image to Imagga
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imagga.com/v2/tags'),
      );
      request.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final tags = data['result']['tags'] as List;

        debugPrint('Top 5 predictions:');
        for (int i = 0; i < 5 && i < tags.length; i++) {
          final tag = tags[i];
          debugPrint('$i: ${tag['tag']['en']} (confidence: ${tag['confidence']})');
        }

        for (final tag in tags) {
          final label = tag['tag']['en'].toString().toLowerCase();
          final confidence = tag['confidence'] as num;
          for (final animal in _animalCategories) {
            if (label.contains(animal)) {
              debugPrint('Found animal: $animal (from $label) with confidence $confidence');
              if (confidence >= _confidenceThreshold * 100) { // Imagga uses 0-100 scale
                return animal;
              }
            }
          }
        }
        return 'unknown';
      } else {
        debugPrint('Imagga API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error detecting animal with Imagga: $e');
      return null;
    }
  }
} 