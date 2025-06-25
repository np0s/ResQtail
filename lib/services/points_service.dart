import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_points.dart';

class PointsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserPoints? _currentUserPoints;
  List<AchievementBadge> _earnedBadges = [];

  UserPoints? get currentUserPoints => _currentUserPoints;
  List<AchievementBadge> get earnedBadges => _earnedBadges;

  Future<void> loadUserPoints(String userId) async {
    try {
      final doc = await _firestore.collection('userPoints').doc(userId).get();
      if (doc.exists) {
        _currentUserPoints = UserPoints.fromJson(doc.data()!);
        _updateEarnedBadges();
      } else {
        // Create new user points record
        _currentUserPoints = UserPoints(
          userId: userId,
          totalPoints: 0,
          reportsSubmitted: 0,
          reportsHelped: 0,
          earnedBadges: [],
          lastUpdated: DateTime.now(),
        );
        await _saveUserPoints();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user points: $e');
    }
  }

  Future<void> _saveUserPoints() async {
    if (_currentUserPoints == null) return;

    try {
      await _firestore
          .collection('userPoints')
          .doc(_currentUserPoints!.userId)
          .set(_currentUserPoints!.toJson());
    } catch (e) {
      debugPrint('Error saving user points: $e');
    }
  }

  Future<int> addPointsForReport(String userId) async {
    if (_currentUserPoints?.userId != userId) {
      await loadUserPoints(userId);
    }

    if (_currentUserPoints == null) return 0;

    final newReportsSubmitted = _currentUserPoints!.reportsSubmitted + 1;
    final newTotalPoints =
        _currentUserPoints!.totalPoints + PointsConfig.pointsPerReport;

    _currentUserPoints = _currentUserPoints!.copyWith(
      reportsSubmitted: newReportsSubmitted,
      totalPoints: newTotalPoints,
      lastUpdated: DateTime.now(),
    );

    await _saveUserPoints();
    await _checkAndAwardBadges();
    notifyListeners();

    return PointsConfig.pointsPerReport;
  }

  Future<int> addPointsForHelp(String userId) async {
    if (_currentUserPoints?.userId != userId) {
      await loadUserPoints(userId);
    }

    if (_currentUserPoints == null) return 0;

    final newReportsHelped = _currentUserPoints!.reportsHelped + 1;
    final newTotalPoints =
        _currentUserPoints!.totalPoints + PointsConfig.pointsPerHelp;

    _currentUserPoints = _currentUserPoints!.copyWith(
      reportsHelped: newReportsHelped,
      totalPoints: newTotalPoints,
      lastUpdated: DateTime.now(),
    );

    await _saveUserPoints();
    await _checkAndAwardBadges();
    notifyListeners();

    return PointsConfig.pointsPerHelp;
  }

  Future<int> deductPointsForReport(String userId) async {
    if (_currentUserPoints?.userId != userId) {
      await loadUserPoints(userId);
    }

    if (_currentUserPoints == null) return 0;

    final newReportsSubmitted = (_currentUserPoints!.reportsSubmitted - 1)
        .clamp(0, double.infinity)
        .toInt();
    final newTotalPoints =
        (_currentUserPoints!.totalPoints - PointsConfig.pointsPerReport)
            .clamp(0, double.infinity)
            .toInt();

    _currentUserPoints = _currentUserPoints!.copyWith(
      reportsSubmitted: newReportsSubmitted,
      totalPoints: newTotalPoints,
      lastUpdated: DateTime.now(),
    );

    await _saveUserPoints();
    await _checkAndAwardBadges();
    notifyListeners();

    return PointsConfig.pointsPerReport;
  }

  Future<void> _checkAndAwardBadges() async {
    if (_currentUserPoints == null) return;

    final newBadges = <String>[];

    for (final badge in PointsConfig.badges) {
      if (_currentUserPoints!.earnedBadges.contains(badge.id)) continue;

      bool shouldAward = false;

      if (badge.requiredReports > 0 &&
          _currentUserPoints!.reportsSubmitted >= badge.requiredReports) {
        shouldAward = true;
      } else if (badge.requiredHelps > 0 &&
          _currentUserPoints!.reportsHelped >= badge.requiredHelps) {
        shouldAward = true;
      } else if (badge.requiredPoints > 0 &&
          _currentUserPoints!.totalPoints >= badge.requiredPoints) {
        shouldAward = true;
      }

      if (shouldAward) {
        newBadges.add(badge.id);
      }
    }

    if (newBadges.isNotEmpty) {
      final updatedBadges = [..._currentUserPoints!.earnedBadges, ...newBadges];
      _currentUserPoints = _currentUserPoints!.copyWith(
        earnedBadges: updatedBadges,
        lastUpdated: DateTime.now(),
      );
      await _saveUserPoints();
      _updateEarnedBadges();
    }
  }

  void _updateEarnedBadges() {
    if (_currentUserPoints == null) {
      _earnedBadges = [];
      return;
    }

    // Clean up invalid badges (badges that no longer exist in the config)
    final validBadgeIds = PointsConfig.badges.map((badge) => badge.id).toSet();
    final cleanedEarnedBadges = _currentUserPoints!.earnedBadges
        .where((badgeId) => validBadgeIds.contains(badgeId))
        .toList();

    // Update the user's earned badges if any were removed
    if (cleanedEarnedBadges.length != _currentUserPoints!.earnedBadges.length) {
      _currentUserPoints = _currentUserPoints!.copyWith(
        earnedBadges: cleanedEarnedBadges,
        lastUpdated: DateTime.now(),
      );
      _saveUserPoints();
    }

    _earnedBadges = PointsConfig.badges
        .where((badge) => _currentUserPoints!.earnedBadges.contains(badge.id))
        .toList();
  }

  List<AchievementBadge> getUnearnedBadges() {
    if (_currentUserPoints == null) return PointsConfig.badges;

    return PointsConfig.badges
        .where((badge) => !_currentUserPoints!.earnedBadges.contains(badge.id))
        .toList();
  }

  AchievementBadge? getBadgeById(String badgeId) {
    try {
      return PointsConfig.badges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  Future<void> awardSpecialBadge(String userId, String badgeId) async {
    if (_currentUserPoints?.userId != userId) {
      await loadUserPoints(userId);
    }

    if (_currentUserPoints == null) return;

    final badge = getBadgeById(badgeId);
    if (badge == null || !badge.isSpecial) return;

    if (!_currentUserPoints!.earnedBadges.contains(badgeId)) {
      final updatedBadges = [..._currentUserPoints!.earnedBadges, badgeId];
      _currentUserPoints = _currentUserPoints!.copyWith(
        earnedBadges: updatedBadges,
        lastUpdated: DateTime.now(),
      );
      await _saveUserPoints();
      _updateEarnedBadges();
      notifyListeners();
    }
  }

  void reset() {
    _currentUserPoints = null;
    _earnedBadges = [];
    notifyListeners();
  }

  Future<void> cleanupInvalidBadges() async {
    try {
      final validBadgeIds =
          PointsConfig.badges.map((badge) => badge.id).toSet();
      final usersSnapshot = await _firestore.collection('userPoints').get();

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        final earnedBadges = List<String>.from(userData['earnedBadges'] ?? []);

        // Remove invalid badges
        final cleanedBadges = earnedBadges
            .where((badgeId) => validBadgeIds.contains(badgeId))
            .toList();

        // Update if any badges were removed
        if (cleanedBadges.length != earnedBadges.length) {
          await _firestore.collection('userPoints').doc(doc.id).update({
            'earnedBadges': cleanedBadges,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
      }

      // Reload current user's data if available
      if (_currentUserPoints != null) {
        await loadUserPoints(_currentUserPoints!.userId);
      }
    } catch (e) {
      debugPrint('Error cleaning up invalid badges: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      // Get user points and badges
      final userPointsDoc =
          await _firestore.collection('userPoints').doc(userId).get();
      List<String> earnedBadgeIds = [];
      if (userPointsDoc.exists) {
        final userData = userPointsDoc.data()!;
        earnedBadgeIds = List<String>.from(userData['earnedBadges'] ?? []);
      }

      // Get user profile info (username, email, etc.) by querying the userId field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .get();
      String username = 'User';
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        username =
            userData['username'] ?? userData['email']?.split('@')[0] ?? 'User';
      }

      // Get badge objects for the earned badges
      final earnedBadges = PointsConfig.badges
          .where((badge) => earnedBadgeIds.contains(badge.id))
          .toList();

      return {
        'userId': userId,
        'username': username,
        'earnedBadges': earnedBadges,
        'earnedBadgeIds': earnedBadgeIds,
      };
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }
}
