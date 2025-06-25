class UserPoints {
  final String userId;
  final int totalPoints;
  final int reportsSubmitted;
  final int reportsHelped;
  final List<String> earnedBadges;
  final DateTime lastUpdated;

  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.reportsSubmitted,
    required this.reportsHelped,
    required this.earnedBadges,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'reportsSubmitted': reportsSubmitted,
      'reportsHelped': reportsHelped,
      'earnedBadges': earnedBadges,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      userId: json['userId'],
      totalPoints: json['totalPoints'] ?? 0,
      reportsSubmitted: json['reportsSubmitted'] ?? 0,
      reportsHelped: json['reportsHelped'] ?? 0,
      earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  UserPoints copyWith({
    String? userId,
    int? totalPoints,
    int? reportsSubmitted,
    int? reportsHelped,
    List<String>? earnedBadges,
    DateTime? lastUpdated,
  }) {
    return UserPoints(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      reportsSubmitted: reportsSubmitted ?? this.reportsSubmitted,
      reportsHelped: reportsHelped ?? this.reportsHelped,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int requiredPoints;
  final int requiredReports;
  final int requiredHelps;
  final bool isSpecial;

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    this.requiredPoints = 0,
    this.requiredReports = 0,
    this.requiredHelps = 0,
    this.isSpecial = false,
  });
}

class PointsConfig {
  static const int pointsPerReport = 10;
  static const int pointsPerHelp = 15;

  static const Map<String, String> badgeEmojis = {
    'first_report': '🎖️',
    'trailblazer': '🐾',
    'pack_leader': '🦴',
    'heart_of_gold': '🧡',
    'rescue_ally': '🤝',
    'guardian_of_tails': '🛡️',
  };

  static const List<AchievementBadge> badges = [
    AchievementBadge(
      id: 'first_report',
      name: 'First Pawprint',
      description: 'Submit your first report',
      iconPath: 'assets/Badges/First_Pawprint.png',
      requiredReports: 1,
    ),
    AchievementBadge(
      id: 'trailblazer',
      name: 'Trailblazer',
      description: 'Submit 5 reports',
      iconPath: 'assets/Badges/Trailblazer.png',
      requiredReports: 5,
    ),
    AchievementBadge(
      id: 'pack_leader',
      name: 'Pack Leader',
      description: 'Submit 10 reports',
      iconPath: 'assets/Badges/Pack_Leader.png',
      requiredReports: 10,
    ),
    AchievementBadge(
      id: 'heart_of_gold',
      name: 'Heart of Gold',
      description: 'Help one animal',
      iconPath: 'assets/Badges/Heart_of_Gold.png',
      requiredHelps: 1,
    ),
    AchievementBadge(
      id: 'rescue_ally',
      name: 'Rescue Ally',
      description: 'Help 5 animals',
      iconPath: 'assets/Badges/Rescue_Ally.png',
      requiredHelps: 5,
    ),
    AchievementBadge(
      id: 'guardian_of_tails',
      name: 'Guardian of Tails',
      description: 'Help 10 animals',
      iconPath: 'assets/Badges/Gaurdian_of_Tails.png',
      requiredHelps: 10,
    ),
  ];
}
