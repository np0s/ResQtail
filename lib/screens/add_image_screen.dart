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
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../models/report.dart';

class AddImageScreen extends StatefulWidget {
  const AddImageScreen({Key? key}) : super(key: key);

  @override
  State<AddImageScreen> createState() => _AddImageScreenState();
}

class _AddImageScreenState extends State<AddImageScreen>
    with SingleTickerProviderStateMixin {
  File? _image;
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
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  LatLng? _pickedLocation;
  LatLng? _initialMapCenter;
  double _cameraCardScale = 1.0;
  final List<String> _customTags = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _setInitialLocation();
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

  Future<void> _pickImage({required ImageSource source}) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _detectedAnimalType = 'Enter animal type'; // Default text
      });
      _animController.forward(from: 0);
    }
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
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image first')),
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
      // Create a unique ID for the report
      final reportId = const Uuid().v4();

      // Create the report
      final report = Report(
        id: reportId,
        userId: userId,
        imagePath: _image!.path,
        description: _descriptionController.text,
        tags: _selectedTags,
        detectedAnimalType: _detectedAnimalType,
        location: _pickedLocation!,
        timestamp: DateTime.now(),
      );

      // Save the report
      await reportService.addReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        // Clear the form
        setState(() {
          _image = null;
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

  @override
  void dispose() {
    _animController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC), Color(0xFFf093fb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: isMobile ? 16 : 80,
              right: isMobile ? 16 : 80,
              top: isMobile ? 24 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Stylish Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'Add Your Report',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.deepPurple[400],
                      shadows: [
                        Shadow(
                          color: Colors.deepPurple.withAlpha(38),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Animated Image Preview or Camera/Gallery Buttons
                MouseRegion(
                  onEnter: (_) => setState(() => _cameraCardScale = 1.05),
                  onExit: (_) => setState(() => _cameraCardScale = 1.0),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _cameraCardScale = 1.08),
                    onTapUp: (_) => setState(() => _cameraCardScale = 1.0),
                    onTapCancel: () => setState(() => _cameraCardScale = 1.0),
                    child: AnimatedScale(
                      scale: _cameraCardScale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: _image == null
                            ? _buildCameraGalleryPrompt(context, isMobile)
                            : FadeTransition(
                                opacity: _fadeAnim,
                                child: Container(
                                  width: isMobile ? 220 : 320,
                                  height: isMobile ? 220 : 320,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(179),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                      width: isMobile ? 220 : 320,
                                      height: isMobile ? 220 : 320,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Map Picker
                Container(
                  width: isMobile ? 280 : 400,
                  height: isMobile ? 200 : 240,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(179),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _isLoadingLocation
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _initialMapCenter == null
                          ? const Center(
                              child: Text('Could not get location'),
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Location pinned'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    gestureRecognizers: <Factory<
                                        OneSequenceGestureRecognizer>>{
                                      Factory<OneSequenceGestureRecognizer>(
                                          () => ScaleGestureRecognizer()
                                            ..onStart =
                                                (ScaleStartDetails details) {
                                              // Smooth zoom start
                                            }
                                            ..onUpdate =
                                                (ScaleUpdateDetails details) {
                                              // Smooth zoom update
                                            }),
                                    },
                                    markers: _pickedLocation == null
                                        ? {}
                                        : {
                                            Marker(
                                              markerId:
                                                  const MarkerId('picked'),
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
                                  bottom: 12,
                                  right: 12,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FloatingActionButton(
                                        heroTag: 'gps',
                                        onPressed: _getCurrentLocation,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        child: const Icon(Icons.gps_fixed,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton(
                                        heroTag: 'pin',
                                        onPressed: () {
                                          // Pin is already at center, so nothing to do
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Location pinned at center'),
                                            ),
                                          );
                                        },
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        child: const Icon(Icons.place,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 28),
                // Image Preview with Change Button
                if (_image != null)
                  Stack(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          width: isMobile ? 220 : 320,
                          height: isMobile ? 220 : 320,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(179),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: isMobile ? 220 : 320,
                              height: isMobile ? 220 : 320,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.deepPurple),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Change Photo'),
                                  content: const Text(
                                      'Would you like to take a new photo or choose from gallery?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _pickImage(source: ImageSource.camera);
                                      },
                                      child: const Text('Take Photo'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _pickImage(source: ImageSource.gallery);
                                      },
                                      child: const Text('Choose from Gallery'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                // Animal Type Input
                if (_image != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(179),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _detectedAnimalType!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: _showEditAnimalTypeDialog,
                          tooltip: 'Edit animal type',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                // Tag Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8),
                    child: Text(
                      'Tags',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[300],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
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
                        backgroundColor: Colors.white.withAlpha(179),
                        selectedColor:
                            Theme.of(context).colorScheme.primary.withAlpha(51),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
                        backgroundColor: Colors.white.withAlpha(179),
                        selectedColor:
                            Theme.of(context).colorScheme.primary.withAlpha(51),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }),
                    ActionChip(
                      label: const Text('Other'),
                      avatar: const Icon(Icons.add, size: 18),
                      onPressed: _showAddTagDialog,
                      backgroundColor: Colors.deepPurple[50],
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Description Field
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withAlpha(51),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add a description...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Submit Button
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Add extra padding at the bottom to account for the navigation bar
                SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraGalleryPrompt(BuildContext context, bool isMobile) {
    final double boxWidth = isMobile ? 280 : 400;
    final double boxHeight = isMobile ? 200 : 240;
    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(77),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(128),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(24),
        dashPattern: const [8, 6],
        color: Theme.of(context).colorScheme.primary.withAlpha(128),
        strokeWidth: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: isMobile ? 56 : 72),
            const SizedBox(height: 12),
            Text(
              'Add a photo of the animal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(source: ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4 : 8,
                            vertical: isMobile ? 10 : 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(source: ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4 : 8,
                            vertical: isMobile ? 10 : 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
