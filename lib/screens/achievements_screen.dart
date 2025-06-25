import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/points_service.dart';
import '../services/auth_service.dart';
import '../widgets/points_display.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late PointsService pointsService;
  late AuthService authService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Services will be assigned in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pointsService = Provider.of<PointsService>(context, listen: false);
    authService = Provider.of<AuthService>(context, listen: false);
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (authService.userId != null) {
        await pointsService.loadUserPoints(authService.userId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading achievements: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6750A4),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<PointsService>(
                    builder: (context, pointsService, child) {
                      return PointsDisplay(
                        userPoints: pointsService.currentUserPoints,
                        earnedBadges: pointsService.earnedBadges,
                        unearnedBadges: pointsService.getUnearnedBadges(),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
