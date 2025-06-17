import 'package:google_maps_flutter/google_maps_flutter.dart';

class Report {
  final String id;
  final String userId;
  final String imagePath;
  final String description;
  final Set<String> tags;
  final String? detectedAnimalType;
  final LatLng location;
  final DateTime timestamp;
  final bool isHelped;

  Report({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.description,
    required this.tags,
    this.detectedAnimalType,
    required this.location,
    required this.timestamp,
    this.isHelped = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'description': description,
      'tags': tags.toList(),
      'detectedAnimalType': detectedAnimalType,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'isHelped': isHelped,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      userId: json['userId'],
      imagePath: json['imagePath'],
      description: json['description'],
      tags: Set<String>.from(json['tags']),
      detectedAnimalType: json['detectedAnimalType'],
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isHelped: json['isHelped'] ?? false,
    );
  }
}
