import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/report.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: Colors.deepPurple.withAlpha(170),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  authService.email ?? 'No email available',
                                  style: TextStyle(
                                    color: Colors.deepPurple.withAlpha(170),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (authService.showPhoneNumber) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.deepPurple.withAlpha(170),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    authService.phoneNumber ??
                                        'No phone available',
                                    style: TextStyle(
                                      color: Colors.deepPurple.withAlpha(170),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Timestamp
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(170),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.deepPurple.withAlpha(76),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Reported on ${report.timestamp.toString().split('.')[0]}',
                              style: TextStyle(
                                color: Colors.deepPurple.withAlpha(76),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAuthor && !report.isHelped) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await reportService.markReportAsHelped(report.id);
                              if (context.mounted) {
                                Navigator.pop(context);
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
