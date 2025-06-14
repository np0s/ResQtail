import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'map_screen.dart'; // Import the MapScreen
import 'profile_screen.dart'; // Import the ProfileScreen
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dotted_border/dotted_border.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<Widget> _screens = [
    // Add Screen
    Builder(
      builder: (context) => _AddImageScreen(),
    ),
    const MapScreen(), // Replace placeholder with actual MapScreen
    const ProfileScreen(), // Use the actual ProfileScreen
  ];

  final List<Color> _bgColors = [
    Color(0xFFF5F7FA),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: _bgColors[_selectedIndex],
      end: _bgColors[_selectedIndex],
    ).animate(_controller);
  }

  void _onItemTapped(int index) {
    setState(() {
      _colorAnimation = ColorTween(
        begin: _bgColors[_selectedIndex],
        end: _bgColors[index],
      ).animate(_controller);
      _selectedIndex = index;
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          body: AnimatedSwitcher(
            duration: Duration(milliseconds: 400),
            child: _screens[_selectedIndex],
          ),
          extendBody: true,
          bottomNavigationBar: _buildBottomNavBar(context),
        );
      },
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Plus Icon
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: _selectedIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[400],
                  size: 32),
              onPressed: () => _onItemTapped(0),
              splashRadius: 28,
            ),
            // Center Map Icon (Floating)
            GestureDetector(
              onTap: () => _onItemTapped(1),
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: Icon(Icons.map,
                    color:
                        _selectedIndex == 1 ? Colors.white : Colors.grey[500],
                    size: 40),
              ),
            ),
            // Profile Icon
            GestureDetector(
              onTap: () => _onItemTapped(2),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: const NetworkImage(
                  'https://upload.wikimedia.org/wikipedia/commons/7/70/User_icon_BLACK-01.png', // General PNG placeholder image
                ),
                backgroundColor: Colors.grey[200],
                child: _selectedIndex == 2
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add Image Upload Screen
class _AddImageScreen extends StatefulWidget {
  @override
  State<_AddImageScreen> createState() => _AddImageScreenState();
}

class _AddImageScreenState extends State<_AddImageScreen>
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
  LatLng? _pickedLocation;
  GoogleMapController? _mapController;
  LatLng _initialMapCenter =
      const LatLng(28.6139, 77.2090); // Default: New Delhi
  double _cameraCardScale = 1.0;
  List<String> _customTags = [];

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
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _initialMapCenter = LatLng(pos.latitude, pos.longitude);
        _pickedLocation = _initialMapCenter;
      });
    } catch (_) {
      // Use default location
      setState(() {
        _pickedLocation = _initialMapCenter;
      });
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _detectedAnimalType = 'Dog'; // Simulate AI detection
      });
      _animController.forward(from: 0);
    }
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

  @override
  void dispose() {
    _animController.dispose();
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
              bottom: MediaQuery.of(context).padding.bottom + 32,
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
                          color: Colors.deepPurple.withOpacity(0.15),
                          blurRadius: 12,
                          offset: Offset(0, 4),
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
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _pickedLocation ?? _initialMapCenter,
                            zoom: 15,
                          ),
                          onMapCreated: (controller) =>
                              _mapController = controller,
                          onCameraMove: (position) {
                            setState(() {
                              _pickedLocation = position.target;
                            });
                          },
                          markers: _pickedLocation == null
                              ? {}
                              : {
                                  Marker(
                                    markerId: const MarkerId('picked'),
                                    position: _pickedLocation!,
                                  ),
                                },
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Pin is always at center, so nothing to do
                          },
                          icon: const Icon(Icons.place),
                          label: const Text('Pin Here'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Animal Type Detection
                if (_detectedAnimalType != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
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
                        Icon(Icons.pets,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Detected: $_detectedAnimalType',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                        backgroundColor: Colors.white.withOpacity(0.7),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
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
                        backgroundColor: Colors.white.withOpacity(0.7),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
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
                // Description Field (thin border, no glass)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.2),
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
                    onPressed: () {
                      // TODO: Implement submit logic
                    },
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
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: Radius.circular(24),
        dashPattern: [8, 6],
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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

// Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
