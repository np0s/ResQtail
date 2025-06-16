import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report.dart';

class ReportService extends ChangeNotifier {
  static const String _reportsFileName = 'reports.json';
  List<Report> _reports = [];

  List<Report> get reports => _reports;
  List<Report> getUserReports(String userId) {
    return _reports.where((report) => report.userId == userId).toList();
  }

  Future<String> get _reportsFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_reportsFileName';
  }

  Future<void> loadReports() async {
    try {
      final file = File(await _reportsFilePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        _reports = jsonList.map((json) => Report.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
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

  Future<void> addReport(Report report) async {
    _reports.add(report);
    await saveReports();
    notifyListeners();
  }

  Future<void> deleteReport(String reportId) async {
    _reports.removeWhere((report) => report.id == reportId);
    await saveReports();
    notifyListeners();
  }
}
