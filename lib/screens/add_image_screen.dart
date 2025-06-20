import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/animal_detection_service.dart';
import '../models/report.dart';
import 'dart:ui';

class AddImageScreen extends StatefulWidget {
  const AddImageScreen({Key? key}) : super(key: key);

  @override
  State<AddImageScreen> createState() => _AddImageScreenState();
}

class _AddImageScreenState extends State<AddImageScreen>
    with SingleTickerProviderStateMixin {
  File? _primaryImage;
  final List<File> _secondaryImages = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _defaultTags = [
    'Injured',
    'Needs Help',
    'Adoption',
    'Abandoned'
  ];
  final Set<String> _selectedTags = {};
  final TextEditingController _descriptionController = TextEditingController();
  String? _detectedAnimalType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  LatLng? _pickedLocation;
  LatLng? _initialMapCenter;
  double _cameraCardScale = 1.0;
  final List<String> _customTags = [];
  final AnimalDetectionService _animalDetectionService =
      AnimalDetectionService();
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _setInitialLocation();
    _animalDetectionService.initialize();
  }

  Future<void> _setInitialLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission permanently denied. Please enable in settings.'),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _initialMapCenter = LatLng(position.latitude, position.longitude);
          _pickedLocation = _initialMapCenter;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_mapController != null) {
        final newPosition = LatLng(position.latitude, position.longitude);
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 15,
            ),
          ),
        );

        setState(() {
          _pickedLocation = newPosition;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  Future<void> _pickPrimaryImage({required ImageSource source}) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _primaryImage = File(pickedFile.path);
        _detectedAnimalType = 'Detecting animal...';
        _isDetecting = true;
      });
      _animationController.forward(from: 0);
      final detectedAnimal =
          await _animalDetectionService.detectAnimal(_primaryImage!);
      if (mounted) {
        setState(() {
          _detectedAnimalType = detectedAnimal ?? 'Unknown Animal';
          _isDetecting = false;
        });
      }
    }
  }

  Future<void> _pickSecondaryImage({required ImageSource source}) async {
    if (source == ImageSource.gallery) {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _secondaryImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _secondaryImages.add(File(pickedFile.path));
        });
      }
    }
  }

  void _removeSecondaryImage(int index) {
    setState(() {
      _secondaryImages.removeAt(index);
    });
  }

  void _showEditAnimalTypeDialog() {
    final TextEditingController editController = TextEditingController(
        text: _detectedAnimalType == 'Enter animal type'
            ? ''
            : _detectedAnimalType);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Animal Type'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: 'Enter animal type',
              labelText: 'Animal Type',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _detectedAnimalType = editController.text.trim().isEmpty
                      ? 'Enter animal type'
                      : editController.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTagDialog() async {
    String newTag = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Tag'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter tag'),
            onChanged: (val) => newTag = val.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTag.isNotEmpty) {
                  setState(() {
                    _customTags.add(newTag);
                    _selectedTags.add(newTag);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (_primaryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a primary image first')),
      );
      return;
    }
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag')),
      );
      return;
    }
    final authService = context.read<AuthService>();
    final reportService = context.read<ReportService>();
    final userId = authService.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a report')),
      );
      return;
    }
    try {
      final reportId = const Uuid().v4();
      final allImagePaths = <String>[
        _primaryImage!.path,
        ..._secondaryImages.map((f) => f.path)
      ];
      final report = Report(
        id: reportId,
        userId: userId,
        imagePaths: allImagePaths,
        description: _descriptionController.text,
        tags: _selectedTags,
        detectedAnimalType: _detectedAnimalType,
        location: _pickedLocation!,
        timestamp: DateTime.now(),
      );
      await reportService.addReport(report);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        setState(() {
          _primaryImage = null;
          _secondaryImages.clear();
          _selectedTags.clear();
          _descriptionController.clear();
          _detectedAnimalType = null;
          _pickedLocation = _initialMapCenter;
        });
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report')),
        );
      }
    }
  }

  void _showAddImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickSecondaryImage(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickSecondaryImage(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    _animalDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E7E9), Color(0xFFE3EEFF), Color(0xFFD9E7FF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Floating heading at the top
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'New Animal Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Step 1: Main Image
              _sectionHeader('1. Add Main Image'),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: GestureDetector(
                  onTap: () => _pickPrimaryImage(source: ImageSource.gallery),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _primaryImage == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 44, color: Colors.deepPurple[200]),
                                const SizedBox(height: 8),
                                Text('Tap to add main photo', style: TextStyle(color: Colors.deepPurple[200])),
                              ],
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_primaryImage!, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _primaryImage = null;
                                    _detectedAnimalType = null;
                                  }),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                    ),
                                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Step 2: Details
              _sectionHeader('2. Details'),
              const SizedBox(height: 8),
              // Animal Type
              Row(
                children: [
                  const Text('Animal Type:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showEditAnimalTypeDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple.withOpacity(0.10)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pets, color: Colors.deepPurple, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _detectedAnimalType ?? 'Tap to enter',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.edit, size: 16, color: Colors.deepPurple),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Tags
              Row(
                children: [
                  const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ..._defaultTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: Colors.deepPurple.withOpacity(0.15),
                            checkmarkColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.deepPurple : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }),
                        ..._customTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: Colors.deepPurple.withOpacity(0.15),
                            checkmarkColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.deepPurple : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }),
                        ActionChip(
                          label: const Text('Add'),
                          avatar: const Icon(Icons.add, size: 16),
                          onPressed: _showAddTagDialog,
                          backgroundColor: Colors.deepPurple[50],
                          labelStyle: const TextStyle(color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.10)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              // Step 3: Location
              _sectionHeader('3. Location'),
              const SizedBox(height: 8),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isLoadingLocation
                      ? const Center(child: CircularProgressIndicator())
                      : _initialMapCenter == null
                          ? const Center(child: Text('Could not get location'))
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _initialMapCenter!,
                                      zoom: 15,
                                    ),
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                    },
                                    onCameraMove: (position) {
                                      setState(() {
                                        _pickedLocation = position.target;
                                      });
                                    },
                                    onTap: (LatLng location) {
                                      setState(() {
                                        _pickedLocation = location;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Location pinned'), duration: Duration(seconds: 1)),
                                      );
                                    },
                                    markers: _pickedLocation == null
                                        ? {}
                                        : {
                                            Marker(
                                              markerId: const MarkerId('picked'),
                                              position: _pickedLocation!,
                                              draggable: true,
                                              onDragEnd: (LatLng newPosition) {
                                                setState(() {
                                                  _pickedLocation = newPosition;
                                                });
                                              },
                                            ),
                                          },
                                    myLocationButtonEnabled: false,
                                    myLocationEnabled: true,
                                    zoomControlsEnabled: false,
                                    zoomGesturesEnabled: true,
                                    scrollGesturesEnabled: true,
                                    rotateGesturesEnabled: true,
                                    tiltGesturesEnabled: true,
                                    compassEnabled: true,
                                    mapToolbarEnabled: true,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: FloatingActionButton(
                                    heroTag: 'gps',
                                    mini: true,
                                    onPressed: _getCurrentLocation,
                                    backgroundColor: Colors.deepPurple,
                                    child: const Icon(Icons.gps_fixed, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),
              // Step 4: More Images (Optional)
              _sectionHeader('4. Add More Images (Optional)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._secondaryImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.deepPurple.withOpacity(0.10)),
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.06), blurRadius: 4, offset: Offset(0,2))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeSecondaryImage(idx),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    GestureDetector(
                      onTap: _showAddImageOptions,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.deepPurple.withOpacity(0.10)),
                        ),
                        child: const Icon(Icons.add, color: Colors.deepPurple),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitReport,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    shadowColor: Colors.deepPurple.withOpacity(0.15),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
        ],
      ),
    );
  }
}

// Glassmorphism Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color color;
  final BorderRadius borderRadius;
  const GlassContainer({super.key, required this.child, this.blur = 10, this.color = Colors.white24, this.borderRadius = BorderRadius.zero});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
