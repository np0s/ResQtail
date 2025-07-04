import 'package:flutter/material.dart';
import 'map_screen.dart'; 
import 'profile_screen.dart'; 
import 'add_image_screen.dart'; 
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:io';

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

  final List<Widget> _screens = [
    const AddImageScreen(),
    const MapScreen(),
    const ProfileScreen(),
  ];

  final List<Color> _bgColors = [
    const Color(0xFFF5F7FA),
    const Color(0xFFE3F2FD),
    const Color(0xFFF3E5F5),
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
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _screens[_selectedIndex],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNavBar(context),
              ),
            ],
          ),
          extendBody: true,
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
        boxShadow: const [
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
                  boxShadow: const [
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
                backgroundImage: context.watch<AuthService>().profileImagePath != null &&
                        context.watch<AuthService>().profileImagePath!.isNotEmpty
                    ? (context.watch<AuthService>().profileImagePath!.startsWith('http')
                        ? NetworkImage(context.watch<AuthService>().profileImagePath!) as ImageProvider<Object>
                        : FileImage(File(context.watch<AuthService>().profileImagePath!)) as ImageProvider<Object>)
                    : const NetworkImage('https://upload.wikimedia.org/wikipedia/commons/7/70/User_icon_BLACK-01.png'),
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
