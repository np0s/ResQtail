import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/points_service.dart';
import '../widgets/points_display.dart';
import 'dart:ui';

class UserAchievementsScreen extends StatelessWidget {
  const UserAchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Achievements'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
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
      ),
    );
  }
}
