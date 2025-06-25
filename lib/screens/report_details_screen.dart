import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/report.dart';
import '../models/user_points.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';
import '../services/points_service.dart';
import '../widgets/points_celebration.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Report report;

  const ReportDetailsScreen({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  int _currentPage = 0;
  late final PageController _pageController;
  Map<String, dynamic>? _authorInfo;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAuthorInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorInfo() async {
    final pointsService = context.read<PointsService>();
    final authorInfo = await pointsService.getUserInfo(widget.report.userId);
    if (mounted) {
      setState(() {
        _authorInfo = authorInfo;
      });
    }
  }

  Future<void> _openInMaps(LatLng location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final reportService = context.watch<ReportService>();
    final isAuthor = authService.userId == widget.report.userId;
    final report = widget.report;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: report.imagePaths.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: report.imagePaths.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final path = report.imagePaths[index];
                                final isNetwork = path.startsWith('http');
                                return isNetwork
                                    ? Image.network(path, fit: BoxFit.cover)
                                    : Image.file(File(path), fit: BoxFit.cover);
                              },
                            ),
                            if (report.imagePaths.length > 1)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    report.imagePaths.length,
                                    (index) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      width: _currentPage == index ? 12 : 8,
                                      height: _currentPage == index ? 12 : 8,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.white.withAlpha(170),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black.withAlpha(24),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(color: Colors.grey[200]),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animal Type
                      Row(
                        children: [
                          Icon(
                            Icons.pets,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            report.detectedAnimalType ?? 'Unknown Animal',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!isAuthor) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final chatService = ChatService();
                              final authService = context.read<AuthService>();
                              final userId = authService.userId;
                              final otherUserId = report.userId;
                              if (userId == null || otherUserId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'User information not available.')),
                                );
                                return;
                              }
                              final chatId = await chatService.createOrGetChat(
                                  userId, otherUserId, report.id);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                        chatId: chatId,
                                        otherUserId: otherUserId),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Start Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Description
                      if (report.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(170),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            report.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Tags
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: report.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(170),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Location
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withAlpha(76),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: report.location,
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('report'),
                                position: report.location,
                              ),
                            },
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _openInMaps(report.location),
                          icon: const Icon(Icons.map),
                          label: const Text('Open in Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contact Information
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(170),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username with badges
                            if (_authorInfo != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.deepPurple.withAlpha(170),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _authorInfo!['username'] ?? 'User',
                                      style: TextStyle(
                                        color: Colors.deepPurple.withAlpha(170),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_authorInfo!['earnedBadges'] != null &&
                                      (_authorInfo!['earnedBadges'] as List)
                                          .isNotEmpty) ...[
                                    ...(_authorInfo!['earnedBadges'] as List)
                                        .map(
                                          (badge) => GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            24),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Image.asset(
                                                          badge.iconPath,
                                                          width: 100,
                                                          height: 100,
                                                          fit: BoxFit.contain,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Container(
                                                              width: 100,
                                                              height: 100,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.2),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .emoji_events,
                                                                color: Colors
                                                                    .deepPurple,
                                                                size: 60,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Text(
                                                          badge.name,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xFF6750A4),
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          badge.description,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        const SizedBox(
                                                            height: 20),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .deepPurple,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
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
                                              padding: const EdgeInsets.only(
                                                  left: 4),
                                              child: Text(
                                                PointsConfig.badgeEmojis[
                                                        badge.id] ??
                                                    '🏆',
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Email
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: Colors.deepPurple.withAlpha(170),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    report.email ?? 'No email available',
                                    style: TextStyle(
                                      color: Colors.deepPurple.withAlpha(170),
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (report.showPhoneNumber == true &&
                                (report.phoneNumber?.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.deepPurple.withAlpha(170),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      report.phoneNumber ??
                                          'No phone available',
                                      style: TextStyle(
                                        color: Colors.deepPurple.withAlpha(170),
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isAuthor && !report.isHelped) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final pointsService =
                                      context.read<PointsService>();
                                  final authService =
                                      context.read<AuthService>();
                                  final userId = authService.userId;

                                  if (userId != null) {
                                    // Check current badges before marking as helped
                                    final currentBadges =
                                        pointsService.earnedBadges.length;

                                    await reportService
                                        .markReportAsHelped(report.id);

                                    if (context.mounted) {
                                      final username = authService.username ??
                                          authService.email?.split('@')[0] ??
                                          'User';
                                      final pointsEarned = await pointsService
                                          .addPointsForHelp(userId);

                                      await pointsService
                                          .loadUserPoints(userId);
                                      final newBadges =
                                          pointsService.earnedBadges.length -
                                              currentBadges;

                                      AchievementBadge? newBadge;
                                      if (newBadges > 0) {
                                        newBadge =
                                            pointsService.earnedBadges.last;
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) =>
                                              PointsCelebration(
                                            username: username,
                                            pointsEarned: pointsService
                                                    .currentUserPoints
                                                    ?.totalPoints ??
                                                0,
                                            badge: newBadge,
                                            onDismiss: () {
                                              Navigator.of(context).pop();
                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    }
                                  } else {
                                    await reportService
                                        .markReportAsHelped(report.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Mark as Helped'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Report'),
                                      content: const Text(
                                        'Are you sure you want to delete this report? This action cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true && context.mounted) {
                                    await reportService.deleteReport(report.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Report deleted successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isAuthor && report.isHelped) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Show confirmation dialog
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Report'),
                                  content: const Text(
                                    'Are you sure you want to delete this report? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldDelete == true && context.mounted) {
                                await reportService.deleteReport(report.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Report deleted successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
