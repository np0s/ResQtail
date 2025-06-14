import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
    const Center(
        child: Text('Map',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
    const Center(
        child: Text('Profile',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
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

class _AddImageScreenState extends State<_AddImageScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final List<String> _tags = ['Injured', 'Needs Help', 'Adoption', 'Abandoned'];
  final Set<String> _selectedTags = {};
  final TextEditingController _descriptionController = TextEditingController();
  String? _detectedAnimalType;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        // Simulate AI detection (replace with actual AI call)
        _detectedAnimalType = 'Dog';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Image Picker
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: _image == null
                    ? Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey[400],
                          size: 80,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: 220,
                          height: 220,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              // Upload Button
              FloatingActionButton.extended(
                onPressed: _pickImage,
                backgroundColor: const Color(0xFF8EC5FC),
                icon: const Icon(Icons.upload_rounded, color: Colors.white),
                label: const Text(
                  'Upload Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 32),
              // Animal Type Detection
              if (_detectedAnimalType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
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
              const SizedBox(height: 32),
              // Tag Selection
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
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
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Location Picker Button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement location picker
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Pin Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Description Field
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a description...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement submit logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
