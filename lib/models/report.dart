import 'package:google_maps_flutter/google_maps_flutter.dart';

class Report {
  final String id;
  final String userId;
  final List<String> imagePaths;
  final String description;
  final Set<String> tags;
  final String? detectedAnimalType;
  final LatLng location;
  final DateTime timestamp;
  final bool isHelped;
  final String? email;
  final String? phoneNumber;
  final bool? showPhoneNumber;

  Report({
    required this.id,
    required this.userId,
    required this.imagePaths,
    required this.description,
    required this.tags,
    this.detectedAnimalType,
    required this.location,
    required this.timestamp,
    this.isHelped = false,
    this.email,
    this.phoneNumber,
    this.showPhoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePaths': imagePaths,
      'description': description,
      'tags': tags.toList(),
      'detectedAnimalType': detectedAnimalType,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'isHelped': isHelped,
      'email': email,
      'phoneNumber': phoneNumber,
      'showPhoneNumber': showPhoneNumber,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      userId: json['userId'],
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      description: json['description'],
      tags: Set<String>.from(json['tags']),
      detectedAnimalType: json['detectedAnimalType'],
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isHelped: json['isHelped'] ?? false,
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      showPhoneNumber: json['showPhoneNumber'],
    );
  }
}
