import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../models/report.dart';
import 'dart:io';
import 'report_details_screen.dart';
import 'settings_screen.dart';
import 'chat_list_screen.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ReportService>().loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final reportService = context.watch<ReportService>();
    final userEmail = authService.email ?? '';
    final userId = authService.userId;
    final userReports =
        userId != null ? reportService.getUserReports(userId) : [];
    final username = authService.username ?? userEmail.split('@')[0];
    final profileImagePath = authService.profileImagePath;

    // Separate reports by helped status
    final unhelpedReports =
        userReports.where((report) => !report.isHelped).toList().cast<Report>();
    final helpedReports =
        userReports.where((report) => report.isHelped).toList().cast<Report>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pending',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Helped',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await authService.logout();
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture, Username, and Email in a single line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple[100],
                      backgroundImage: profileImagePath != null &&
                              profileImagePath.isNotEmpty
                          ? (profileImagePath.startsWith('http')
                              ? NetworkImage(profileImagePath)
                                  as ImageProvider<Object>
                              : FileImage(File(profileImagePath))
                                  as ImageProvider<Object>)
                          : null,
                      child:
                          profileImagePath == null || profileImagePath.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.deepPurple, size: 40)
                              : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.deepPurple.withAlpha(170),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Messages'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatListScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Achievement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AchievementsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Reports Section with Tabs
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Pending Reports Tab
                            _buildReportsList(
                                unhelpedReports, 'No pending reports'),
                            // Helped Reports Tab
                            _buildReportsList(
                                helpedReports, 'No helped reports'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList(List<Report> reports, String emptyMessage) {
    return reports.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.deepPurple.withAlpha(128),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple.withAlpha(170),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportDetailsScreen(report: report),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: report.imagePaths.isNotEmpty
                              ? (report.imagePaths[0].startsWith('http')
                                  ? Image.network(report.imagePaths[0],
                                      width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.file(File(report.imagePaths[0]),
                                      width: 80, height: 80, fit: BoxFit.cover))
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image,
                                      size: 40, color: Colors.grey[600]),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      report.detectedAnimalType ??
                                          'Unknown Animal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (report.isHelped)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Helped',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.deepPurple.withAlpha(170),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.deepPurple.withAlpha(170),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${report.location.latitude.toStringAsFixed(4)}, ${report.location.longitude.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        color: Colors.deepPurple.withAlpha(170),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
