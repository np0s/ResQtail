import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math';
import '../services/report_service.dart';
import '../models/report.dart';
import '../models/user_points.dart';
import '../services/points_service.dart';
import 'report_details_screen.dart';
import '../services/auth_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final Set<Marker> _filteredMarkers = {};
  Report? _selectedReport;
  Map<String, dynamic>? _authorInfo;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isDetailsVisible = false;

  // Search functionality
  bool _isSearchMode = false;
  bool _isTyping = false;
  String? _selectedSearchTag;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _defaultTags = [
    'Injured',
    'Needs Help',
    'Adoption',
    'Abandoned'
  ];

  @override
  void initState() {
    super.initState();
    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _getCurrentLocation();
    context.read<ReportService>().loadReports();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        _addCurrentLocationMarker();
        _addReportMarkers();

        // Animate camera to current location
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15,
            ),
          );
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to show the map'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
          ),
        );
      }
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      if (!mounted) return;
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(
              title: 'Current Location',
              snippet: 'You are here',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            alpha: 0.7,
          ),
        );
      });
    }
  }

  void _addReportMarkers() {
    final reportService = context.read<ReportService>();
    final reports = reportService.reports;

    for (final report in reports) {
      if (!mounted) return;
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(report.id),
            position: report.location,
            onTap: () => _onMarkerTapped(report),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        );
      });
    }
    _filteredMarkers.addAll(_markers);
  }

  void _onMarkerTapped(Report report) async {
    setState(() {
      _selectedReport = report;
      _isDetailsVisible = true;
    });

    // Load author info
    await _loadAuthorInfo(report.userId);

    // Animate camera to the marker
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(report.location, 15),
    );

    // Start the slide animation
    _animationController.forward();
  }

  Future<void> _loadAuthorInfo(String userId) async {
    final pointsService = context.read<PointsService>();
    final authorInfo = await pointsService.getUserInfo(userId);
    if (mounted) {
      setState(() {
        _authorInfo = authorInfo;
      });
    }
  }

  void _closeDetails() {
    _animationController.reverse().then((_) {
      setState(() {
        _isDetailsVisible = false;
        _selectedReport = null;
        _authorInfo = null;
      });
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _selectedSearchTag = null;
        _isTyping = false;
        _searchController.clear();
        _filteredMarkers.clear();
        _filteredMarkers.addAll(_markers);
      }
    });
  }

  void _selectSearchTag(String tag) {
    setState(() {
      _selectedSearchTag = tag;
      _searchController.text = tag;
      _isTyping = true;
      _filteredMarkers.clear();

      // Add current location marker
      _filteredMarkers.addAll(_markers
          .where((marker) => marker.markerId.value == 'currentLocation'));

      // Add filtered report markers
      final reportService = context.read<ReportService>();
      final reports = reportService.reports;

      for (final report in reports) {
        if (report.tags.contains(tag)) {
          _filteredMarkers.add(
            Marker(
              markerId: MarkerId(report.id),
              position: report.location,
              onTap: () => _onMarkerTapped(report),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
            ),
          );
        }
      }
    });

    // Check if any reports match the tag
    final reportService = context.read<ReportService>();
    final matchingReports = reportService.reports
        .where((report) => report.tags.contains(tag))
        .toList();

    if (matchingReports.isEmpty) {
      _showNoMatchDialog();
    } else {
      _zoomToShowAllMarkers();
    }
  }

  void _searchByText(String searchText) {
    setState(() {
      _isTyping = searchText.isNotEmpty;
    });

    if (searchText.trim().isEmpty) {
      setState(() {
        _selectedSearchTag = null;
        _isTyping = false;
        _filteredMarkers.clear();
        _filteredMarkers.addAll(_markers);
      });
      return;
    }

    setState(() {
      _selectedSearchTag = searchText.trim();
      _filteredMarkers.clear();

      // Add current location marker
      _filteredMarkers.addAll(_markers
          .where((marker) => marker.markerId.value == 'currentLocation'));

      // Add filtered report markers
      final reportService = context.read<ReportService>();
      final reports = reportService.reports;

      for (final report in reports) {
        if (report.tags.any(
            (tag) => tag.toLowerCase().contains(searchText.toLowerCase()))) {
          _filteredMarkers.add(
            Marker(
              markerId: MarkerId(report.id),
              position: report.location,
              onTap: () => _onMarkerTapped(report),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
            ),
          );
        }
      }
    });

    // Check if any reports match the search
    final reportService = context.read<ReportService>();
    final matchingReports = reportService.reports
        .where((report) => report.tags
            .any((tag) => tag.toLowerCase().contains(searchText.toLowerCase())))
        .toList();

    if (matchingReports.isEmpty) {
      _showNoMatchDialog();
    } else {
      _zoomToShowAllMarkers();
    }
  }

  void _zoomToShowAllMarkers() {
    if (_filteredMarkers.isEmpty || _mapController == null) return;

    // Get all report markers (excluding current location)
    final reportMarkers = _filteredMarkers
        .where((marker) => marker.markerId.value != 'currentLocation')
        .toList();

    if (reportMarkers.isEmpty) return;

    // Calculate bounds to include all markers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in reportMarkers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    // Add some padding
    const padding = 0.01; // About 1km
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    // Animate camera to show all markers
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50px padding
    );
  }

  void _showNoMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Matches Found'),
        content: Text('No reports found with the tag "$_selectedSearchTag"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleSearchMode();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        extendBodyBehindAppBar: true,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentPosition == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Location permission is required',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _filteredMarkers,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              compassEnabled: true,
            ),
            // Custom location button positioned on the right side
            Positioned(
              top: 100,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'location',
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
              ),
            ),
            // Custom zoom controls positioned on the right side
            Positioned(
              top: 180,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
            // Search bar at the top
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                color: const Color(0xFFF3E5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isSearchMode
                            ? TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Type to search tags...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                onChanged: _searchByText,
                                style: const TextStyle(fontSize: 14),
                              )
                            : GestureDetector(
                                onTap: _toggleSearchMode,
                                child: Text(
                                  _selectedSearchTag ?? 'Search by tags...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedSearchTag != null
                                        ? Colors.blue
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                      ),
                      if (_isSearchMode)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _toggleSearchMode,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Tag selection overlay when in search mode
            if (_isSearchMode && !_isTyping)
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isTyping ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Select a tag to filter:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _defaultTags.map((tag) {
                              final isSelected = _selectedSearchTag == tag;
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _selectSearchTag(tag);
                                  } else {
                                    setState(() {
                                      _selectedSearchTag = null;
                                      _filteredMarkers.clear();
                                      _filteredMarkers.addAll(_markers);
                                    });
                                  }
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: Colors.blue.withOpacity(0.2),
                                checkmarkColor: Colors.blue,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isDetailsVisible && _selectedReport != null)
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: Transform.translate(
                      offset: Offset(0, -_slideAnimation.value * 100),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _selectedReport!
                                            .imagePaths.isNotEmpty
                                        ? (_selectedReport!.imagePaths[0]
                                                .startsWith('http')
                                            ? Image.network(
                                                _selectedReport!.imagePaths[0],
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover)
                                            : Image.file(
                                                File(_selectedReport!
                                                    .imagePaths[0]),
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover))
                                        : Container(
                                            width: 64,
                                            height: 64,
                                            color: Colors.grey[300]),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedReport!.detectedAnimalType ??
                                              'Unknown Animal',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (_selectedReport!.tags.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(
                                                      (0.1 * 255).toInt()),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              _selectedReport!.tags.first,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(
                                              _selectedReport!.timestamp),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _closeDetails,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: context.read<AuthService>().userId ==
                                        _selectedReport!.userId
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ReportDetailsScreen(
                                                            report:
                                                                _selectedReport!),
                                                  ),
                                                );
                                              },
                                              icon:
                                                  const Icon(Icons.visibility),
                                              label: const Text('View Details'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                // Show confirmation dialog
                                                final shouldDelete =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Delete Report'),
                                                    content: const Text(
                                                        'Are you sure you want to delete this report? This action cannot be undone.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        style: TextButton
                                                            .styleFrom(
                                                                foregroundColor:
                                                                    Colors.red),
                                                        child: const Text(
                                                            'Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (shouldDelete == true &&
                                                    context.mounted) {
                                                  await context
                                                      .read<ReportService>()
                                                      .deleteReport(
                                                          _selectedReport!.id);
                                                  if (context.mounted) {
                                                    _closeDetails();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Report deleted successfully'),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.delete),
                                              label: const Text('Delete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ReportDetailsScreen(
                                                      report: _selectedReport!),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('View Details'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                              ),
                              // Contact Information
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withAlpha((0.7 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    // Username with badges
                                    if (_authorInfo != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: Colors.deepPurple
                                                .withAlpha((0.7 * 255).toInt()),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _authorInfo!['username'] ??
                                                  'User',
                                              style: TextStyle(
                                                color: Colors.deepPurple
                                                    .withAlpha(
                                                        (0.7 * 255).toInt()),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (_authorInfo!['earnedBadges'] !=
                                                  null &&
                                              (_authorInfo!['earnedBadges']
                                                      as List)
                                                  .isNotEmpty) ...[
                                            ...(_authorInfo!['earnedBadges']
                                                    as List)
                                                .map(
                                                  (badge) => GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
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
                                                                    .all(24),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Image.asset(
                                                                  badge
                                                                      .iconPath,
                                                                  width: 100,
                                                                  height: 100,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return Container(
                                                                      width:
                                                                          100,
                                                                      height:
                                                                          100,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(0.2),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      child:
                                                                          const Icon(
                                                                        Icons
                                                                            .emoji_events,
                                                                        color: Colors
                                                                            .deepPurple,
                                                                        size:
                                                                            60,
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
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Color(
                                                                        0xFF6750A4),
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
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
                                                                        Colors
                                                                            .white,
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 2),
                                                      child: Text(
                                                        PointsConfig.badgeEmojis[
                                                                badge.id] ??
                                                            '🏆',
                                                        style: const TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    // Email
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          color: Colors.deepPurple
                                              .withAlpha((0.7 * 255).toInt()),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _selectedReport!.email ??
                                                'No email available',
                                            style: TextStyle(
                                              color: Colors.deepPurple
                                                  .withAlpha(
                                                      (0.7 * 255).toInt()),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_selectedReport!.showPhoneNumber ==
                                            true &&
                                        (_selectedReport!
                                                .phoneNumber?.isNotEmpty ??
                                            false)) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            color: Colors.deepPurple
                                                .withAlpha((0.7 * 255).toInt()),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _selectedReport!.phoneNumber ??
                                                  'No phone available',
                                              style: TextStyle(
                                                color: Colors.deepPurple
                                                    .withAlpha(
                                                        (0.7 * 255).toInt()),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }
}
