import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/points_service.dart';
import '../services/auth_service.dart';
import '../widgets/points_display.dart';
import '../models/user_points.dart';
import 'user_achievements_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late PointsService pointsService;
  late AuthService authService;
  bool _isLoading = true;
  List<UserPoints> _leaderboard = [];

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (authService.userId != null) {
        await pointsService.loadUserPoints(authService.userId!);
      }
      final leaderboard = await pointsService.getLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
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
    final username =
        authService.username ?? authService.email?.split('@')[0] ?? 'User';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
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
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAchievementsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Achievements'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color:
                                Color(0x266750A4), // Deep purple with opacity
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _leaderboard.isEmpty
                          ? const Center(child: Text('No leaderboard data'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 8),
                              itemCount: _leaderboard.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final user = _leaderboard[index];
                                return FutureBuilder<Map<String, dynamic>?>(
                                  future:
                                      pointsService.getUserInfo(user.userId),
                                  builder: (context, snapshot) {
                                    final username =
                                        snapshot.data?['username'] ??
                                            user.userId.substring(0, 6);
                                    final earnedBadges =
                                        snapshot.data?['earnedBadges']
                                                as List<dynamic>? ??
                                            [];
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: Duration(
                                          milliseconds: 400 + index * 80),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, (1 - value) * 20),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.07),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.deepPurple[100],
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        username,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    for (final badge
                                                        in earnedBadges)
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    Dialog(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        24),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      PointsConfig
                                                                              .badgeEmojis[badge.id] ??
                                                                          '',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              48),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    Text(
                                                                      badge
                                                                          .name,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            20,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Color(
                                                                            0xFF6750A4),
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      badge
                                                                          .description,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            20),
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.deepPurple,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                        ),
                                                                      ),
                                                                      child: const Text(
                                                                          'Close'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      2.0),
                                                          child: Text(
                                                            PointsConfig.badgeEmojis[
                                                                    badge.id] ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        22),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${user.totalPoints} pts',
                                                style: const TextStyle(
                                                  color: Colors.deepPurple,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    // Removed the Leaderboard text from the bottom
                  ],
                ),
        ),
      ),
    );
  }
}
