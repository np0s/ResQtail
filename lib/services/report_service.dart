import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportService extends ChangeNotifier {
  static const String _reportsFileName = 'reports.json';
  List<Report> _reports = [];
  final _firestore = FirebaseFirestore.instance;

  List<Report> get reports =>
      _reports.where((report) => !report.isHelped).toList();
  List<Report> getUserReports(String userId) {
    return _reports.where((report) => report.userId == userId).toList();
  }

  Future<String> get _reportsFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_reportsFileName';
  }

  Future<void> loadReports() async {
    try {
      // Load from Firestore (all reports)
      final snapshot = await _firestore.collection('reports').get();
      _reports = snapshot.docs.map((doc) => Report.fromJson(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reports from Firestore: $e');
      // Fallback to local file for legacy data
      try {
        final file = File(await _reportsFilePath);
        if (await file.exists()) {
          final contents = await file.readAsString();
          final List<dynamic> jsonList = json.decode(contents);
          _reports = jsonList.map((json) => Report.fromJson(json)).toList();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error loading reports from file: $e');
      }
    }
  }

  Future<void> saveReports() async {
    try {
      final file = File(await _reportsFilePath);
      final jsonList = _reports.map((report) => report.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving reports: $e');
    }
  }

  Future<List<String>> _uploadReportImages(String reportId, List<String> imagePaths) async {
    final storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];
    for (int i = 0; i < imagePaths.length; i++) {
      final file = File(imagePaths[i]);
      final ref = storage.ref().child('reports/$reportId/image_$i.jpg');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<void> addReport(Report report) async {
    try {
      // Upload images to Firebase Storage and get URLs
      final imageUrls = await _uploadReportImages(report.id, report.imagePaths);
      final reportWithUrls = Report(
        id: report.id,
        userId: report.userId,
        imagePaths: imageUrls,
        description: report.description,
        tags: report.tags,
        detectedAnimalType: report.detectedAnimalType,
        location: report.location,
        timestamp: report.timestamp,
        isHelped: report.isHelped,
      );
      await _firestore.collection('reports').doc(report.id).set(reportWithUrls.toJson());
      _reports.add(reportWithUrls);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding report to Firestore: $e');
      // Fallback to local file for legacy support
      _reports.add(report);
      await saveReports();
      notifyListeners();
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
      _reports.removeWhere((report) => report.id == reportId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting report from Firestore: $e');
      _reports.removeWhere((report) => report.id == reportId);
      await saveReports();
      notifyListeners();
    }
  }

  Future<void> markReportAsHelped(String reportId) async {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      final updatedReport = Report(
        id: report.id,
        userId: report.userId,
        imagePaths: report.imagePaths,
        description: report.description,
        tags: report.tags,
        detectedAnimalType: report.detectedAnimalType,
        location: report.location,
        timestamp: report.timestamp,
        isHelped: true,
      );
      try {
        await _firestore.collection('reports').doc(reportId).update({'isHelped': true});
        _reports[index] = updatedReport;
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating report in Firestore: $e');
        _reports[index] = updatedReport;
        await saveReports();
        notifyListeners();
      }
    }
  }
}
