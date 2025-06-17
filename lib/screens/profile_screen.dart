import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'report_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _usernameController;
  bool _isEditingUsername = false;
  String? _username;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<ReportService>().loadReports();
    final authService = context.read<AuthService>();
    final userEmail = authService.email ?? '';
    _username = userEmail.split('@')[0];
    _usernameController = TextEditingController(text: _username);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await context.read<AuthService>().setProfileImagePath(image.path);
    }

  Future<void> _deleteProfilePicture() async {
    await context.read<AuthService>().setProfileImagePath('');
  }

  @override
  void dispose() {
    _usernameController.dispose();
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
    final username = _username ?? userEmail.split('@')[0];
    final profileImagePath = authService.profileImagePath;

    return Container(
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
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with User Info and Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text(
                                            'Change Profile Picture'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage();
                                        },
                                      ),
                                      if (profileImagePath != null &&
                                          profileImagePath.isNotEmpty)
                                        ListTile(
                                          leading:
                                              const Icon(Icons.delete_outline),
                                          title: const Text(
                                              'Delete Profile Picture'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _deleteProfilePicture();
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.deepPurple[100],
                                backgroundImage: profileImagePath != null &&
                                        profileImagePath.isNotEmpty
                                    ? FileImage(File(profileImagePath))
                                    : null,
                                child: profileImagePath == null ||
                                        profileImagePath.isEmpty
                                    ? Icon(Icons.person,
                                        color: Colors.deepPurple, size: 32)
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isEditingUsername
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _usernameController,
                                            autofocus: true,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check,
                                              color: Colors.deepPurple),
                                          onPressed: () {
                                            setState(() {
                                              _username =
                                                  _usernameController.text;
                                              _isEditingUsername = false;
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            username,
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.deepPurple),
                                          onPressed: () {
                                            setState(() {
                                              _isEditingUsername = true;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.deepPurple.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<AuthService>().logout();
                    },
                    icon: const Icon(Icons.logout, color: Colors.deepPurple),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.withOpacity(0.1),
                      Colors.deepPurple.withOpacity(0.3),
                      Colors.deepPurple.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Your Reports Section
              const Text(
                'Your Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              // Reports List
              Expanded(
                child: userReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.deepPurple.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reports yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.deepPurple.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: userReports.length,
                        itemBuilder: (context, index) {
                          final report = userReports[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(report.imagePath),
                                        height: 64,
                                        width: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.detectedAnimalType ??
                                                'Unknown Animal',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (report.tags.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Text(
                                                    report.tags.first,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatDate(report.timestamp),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.deepPurple, size: 28),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }
}
