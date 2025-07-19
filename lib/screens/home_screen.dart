import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'add_image_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:io';
import 'achievements_screen.dart';
import 'chat_list_screen.dart';
import '../widgets/ai_assistant_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  final List<Widget> _screens = [
    const AchievementsScreen(), // Leaderboard
    const MapScreen(),
    const AddImageScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  final List<Color> _bgColors = [
    const Color(0xFFF5F7FA),
    const Color(0xFFE3F2FD),
    const Color(0xFFFFFFFF),
    const Color(0xFFE1BEE7),
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
        return Stack(
          children: [
            Scaffold(
              backgroundColor: _colorAnimation.value,
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _screens[_selectedIndex],
              ),
              extendBody: true,
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events,
                                  color: _selectedIndex == 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[400]),
                              const SizedBox(height: 2),
                              const Text('Leaderboard',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map,
                                  color: _selectedIndex == 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[400]),
                              const SizedBox(height: 2),
                              const Text('Map', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Space for the FAB
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(3),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat,
                                  color: _selectedIndex == 3
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[400]),
                              const SizedBox(height: 2),
                              const Text('Chats',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: context
                                                .watch<AuthService>()
                                                .profileImagePath !=
                                            null &&
                                        context
                                            .watch<AuthService>()
                                            .profileImagePath!
                                            .isNotEmpty
                                    ? (context
                                            .watch<AuthService>()
                                            .profileImagePath!
                                            .startsWith('http')
                                        ? NetworkImage(context
                                                .watch<AuthService>()
                                                .profileImagePath!)
                                            as ImageProvider<Object>
                                        : FileImage(File(context
                                                .watch<AuthService>()
                                                .profileImagePath!))
                                            as ImageProvider<Object>)
                                    : const NetworkImage(
                                        'https://upload.wikimedia.org/wikipedia/commons/7/70/User_icon_BLACK-01.png'),
                                backgroundColor: Colors.grey[200],
                                child: _selectedIndex == 4
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 3,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              const Text('Profile',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 8,
                shape: const CircleBorder(), // Ensure circular shape
                child: const Icon(Icons.add, size: 32),
                onPressed: () => _onItemTapped(2),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
            ),
            // AI Assistant Button
            Positioned(
              bottom: 90,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'ai-assistant',
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child:
                    const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    isScrollControlled: true,
                    builder: (context) => const AIAssistantSheet(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
