import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bug_report.dart';
import '../models/device_info.dart';
import '../models/log_entry.dart';
import 'logger.dart';

/// Configuration for bug report manager
class BugReportConfig {
  /// Maximum number of bug reports to keep in storage
  final int maxReports;
  
  /// Whether to include recent logs automatically
  final bool autoIncludeLogs;
  
  /// Number of recent logs to include
  final int maxLogsPerReport;
  
  /// Default tags to add to all reports
  final List<String> defaultTags;
  
  /// Whether to collect device info automatically
  final bool autoCollectDeviceInfo;

  const BugReportConfig({
    this.maxReports = 100,
    this.autoIncludeLogs = true,
    this.maxLogsPerReport = 50,
    this.defaultTags = const [],
    this.autoCollectDeviceInfo = true,
  });
}

/// Manages bug reports creation, storage, and sharing
class BugReportManager {
  static BugReportManager? _instance;
  
  /// Get the singleton instance
  static BugReportManager get instance => _instance ??= BugReportManager._();
  
  BugReportManager._();

  BugReportConfig _config = const BugReportConfig();
  final List<BugReport> _reports = [];
  final StreamController<BugReport> _reportStreamController = 
      StreamController<BugReport>.broadcast();
  
  File? _reportsFile;
  bool _initialized = false;

  /// Stream of new bug reports
  Stream<BugReport> get reportStream => _reportStreamController.stream;

  /// Current configuration
  BugReportConfig get config => _config;

  /// All bug reports
  List<BugReport> get reports => List.unmodifiable(_reports);

  /// Initialize the bug report manager
  Future<void> initialize([BugReportConfig? config]) async {
    if (_initialized) return;
    
    _config = config ?? _config;
    
    await _initializeStorage();
    await _loadReports();
    
    _initialized = true;
  }

  /// Initialize storage for bug reports
  Future<void> _initializeStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/bug_reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      _reportsFile = File('${reportsDir.path}/bug_reports.json');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize bug report storage: $e');
      }
    }
  }

  /// Load existing bug reports from storage
  Future<void> _loadReports() async {
    if (_reportsFile == null || !await _reportsFile!.exists()) return;
    
    try {
      final content = await _reportsFile!.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      
      _reports.clear();
      for (final json in jsonList) {
        try {
          final report = BugReport.fromJson(json);
          _reports.add(report);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to load bug report: $e');
          }
        }
      }
      
      // Sort by timestamp (newest first)
      _reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Maintain max reports limit
      if (_reports.length > _config.maxReports) {
        _reports.removeRange(_config.maxReports, _reports.length);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load bug reports: $e');
      }
    }
  }

  /// Save bug reports to storage
  Future<void> _saveReports() async {
    if (_reportsFile == null) return;
    
    try {
      final jsonList = _reports.map((report) => report.toJson()).toList();
      final content = jsonEncode(jsonList);
      await _reportsFile!.writeAsString(content);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save bug reports: $e');
      }
    }
  }

  /// Create a new bug report
  Future<BugReport> createBugReport({
    required String title,
    required String description,
    required BugSeverity severity,
    required List<String> stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    List<String> attachments = const [],
    Map<String, dynamic>? metadata,
    String? reportedBy,
    List<String>? tags,
    List<LogEntry>? customLogs,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Collect device info if enabled
    DeviceInfo deviceInfo = const DeviceInfo();
    if (_config.autoCollectDeviceInfo) {
      try {
        deviceInfo = await DeviceInfo.collect();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to collect device info: $e');
        }
      }
    }

    // Include recent logs if enabled
    List<LogEntry> logs = customLogs ?? [];
    if (_config.autoIncludeLogs && customLogs == null) {
      logs = BugReportLogger.instance.getRecentLogs(_config.maxLogsPerReport);
    }

    // Merge tags
    final finalTags = <String>[
      ...(_config.defaultTags),
      ...(tags ?? []),
    ].toSet().toList();

    final bugReport = BugReport.create(
      title: title,
      description: description,
      severity: severity,
      stepsToReproduce: stepsToReproduce,
      deviceInfo: deviceInfo,
      logs: logs,
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      attachments: attachments,
      metadata: metadata,
      reportedBy: reportedBy,
      tags: finalTags,
    );

    await _addBugReport(bugReport);
    return bugReport;
  }

  /// Add a bug report to storage
  Future<void> _addBugReport(BugReport report) async {
    _reports.insert(0, report); // Add to beginning (newest first)
    
    // Maintain max reports limit
    if (_reports.length > _config.maxReports) {
      _reports.removeLast();
    }

    await _saveReports();
    _reportStreamController.add(report);
    
    // Log the bug report creation
    BugReportLogger.instance.info(
      'Bug report created: ${report.title}',
      tag: 'BugReportManager',
      metadata: {
        'reportId': report.id,
        'severity': report.severity.name,
      },
    );
  }

  /// Get bug reports filtered by severity
  List<BugReport> getReportsBySeverity(BugSeverity severity) {
    return _reports.where((report) => report.severity == severity).toList();
  }

  /// Get bug reports filtered by tag
  List<BugReport> getReportsByTag(String tag) {
    return _reports.where((report) => report.tags.contains(tag)).toList();
  }

  /// Get bug reports within a date range
  List<BugReport> getReportsByDateRange(DateTime start, DateTime end) {
    return _reports.where((report) {
      return report.timestamp.isAfter(start) && report.timestamp.isBefore(end);
    }).toList();
  }

  /// Search bug reports by title or description
  List<BugReport> searchReports(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _reports.where((report) {
      return report.title.toLowerCase().contains(lowercaseQuery) ||
             report.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get a bug report by ID
  BugReport? getReportById(String id) {
    try {
      return _reports.firstWhere((report) => report.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update an existing bug report
  Future<bool> updateBugReport(String id, BugReport updatedReport) async {
    final index = _reports.indexWhere((report) => report.id == id);
    if (index == -1) return false;
    
    _reports[index] = updatedReport;
    await _saveReports();
    
    BugReportLogger.instance.info(
      'Bug report updated: ${updatedReport.title}',
      tag: 'BugReportManager',
      metadata: {'reportId': id},
    );
    
    return true;
  }

  /// Delete a bug report
  Future<bool> deleteBugReport(String id) async {
    final index = _reports.indexWhere((report) => report.id == id);
    if (index == -1) return false;
    
    final report = _reports.removeAt(index);
    await _saveReports();
    
    BugReportLogger.instance.info(
      'Bug report deleted: ${report.title}',
      tag: 'BugReportManager',
      metadata: {'reportId': id},
    );
    
    return true;
  }

  /// Export all bug reports as formatted text
  String exportAllReports() {
    final buffer = StringBuffer();
    buffer.writeln('📋 BUG REPORTS EXPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Reports: ${_reports.length}');
    buffer.writeln('=' * 60);
    buffer.writeln();
    
    for (int i = 0; i < _reports.length; i++) {
      buffer.writeln('Report ${i + 1}/${_reports.length}');
      buffer.writeln(_reports[i].toFormattedString());
      buffer.writeln('\n${'=' * 60}\n');
    }
    
    return buffer.toString();
  }

  /// Export a single bug report
  String exportReport(String id) {
    final report = getReportById(id);
    if (report == null) return 'Bug report not found: $id';
    
    return report.toFormattedString();
  }

  /// Get bug report statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'totalReports': _reports.length,
      'bySeverity': <String, int>{},
      'byTag': <String, int>{},
      'recentReports': _reports.where((report) {
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return report.timestamp.isAfter(weekAgo);
      }).length,
    };
    
    // Count by severity
    for (final severity in BugSeverity.values) {
      final count = _reports.where((report) => report.severity == severity).length;
      stats['bySeverity'][severity.name] = count;
    }
    
    // Count by tags
    final allTags = <String>[];
    for (final report in _reports) {
      allTags.addAll(report.tags);
    }
    
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    stats['byTag'] = tagCounts;
    
    return stats;
  }

  /// Clear all bug reports
  Future<void> clearAllReports() async {
    _reports.clear();
    await _saveReports();
    
    BugReportLogger.instance.info(
      'All bug reports cleared',
      tag: 'BugReportManager',
    );
  }

  /// Get the storage file path
  String? get reportsFilePath => _reportsFile?.path;

  /// Dispose of resources
  void dispose() {
    _reportStreamController.close();
    _instance = null;
    _initialized = false;
  }
}
