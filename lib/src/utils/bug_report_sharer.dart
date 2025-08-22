import 'dart:io';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bug_report.dart';
import '../core/bug_report_manager.dart';
import '../core/logger.dart';

/// Utility class for sharing bug reports
class BugReportSharer {
  /// Share a single bug report as text
  static Future<void> shareBugReport(
    String reportId, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final report = BugReportManager.instance.getReportById(reportId);
      if (report == null) {
        throw Exception('Bug report not found: $reportId');
      }

      final content = report.toFormattedString();
      final shareSubject = subject ?? 'Bug Report: ${report.title}';

      await Share.share(
        content,
        subject: shareSubject,
        sharePositionOrigin: sharePositionOrigin,
      );

      BugReportLogger.instance.info(
        'Bug report shared: ${report.title}',
        tag: 'BugReportSharer',
        metadata: {'reportId': reportId},
      );
    } catch (e) {
      BugReportLogger.instance.error(
        'Failed to share bug report: $e',
        tag: 'BugReportSharer',
        metadata: {'reportId': reportId},
      );
      rethrow;
    }
  }

  /// Share multiple bug reports as a single text
  static Future<void> shareMultipleReports(
    List<String> reportIds, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final reports = <BugReport>[];
      for (final id in reportIds) {
        final report = BugReportManager.instance.getReportById(id);
        if (report != null) {
          reports.add(report);
        }
      }

      if (reports.isEmpty) {
        throw Exception('No valid bug reports found');
      }

      final buffer = StringBuffer();
      buffer.writeln('📋 MULTIPLE BUG REPORTS');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('Total Reports: ${reports.length}');
      buffer.writeln('=' * 60);
      buffer.writeln();

      for (int i = 0; i < reports.length; i++) {
        buffer.writeln('Report ${i + 1}/${reports.length}');
        buffer.writeln(reports[i].toFormattedString());
        if (i < reports.length - 1) {
          buffer.writeln('\n${'=' * 60}\n');
        }
      }

      final shareSubject = subject ?? 'Bug Reports (${reports.length} reports)';

      await Share.share(
        buffer.toString(),
        subject: shareSubject,
        sharePositionOrigin: sharePositionOrigin,
      );

      BugReportLogger.instance.info(
        'Multiple bug reports shared',
        tag: 'BugReportSharer',
        metadata: {
          'reportCount': reports.length,
          'reportIds': reportIds,
        },
      );
    } catch (e) {
      BugReportLogger.instance.error(
        'Failed to share multiple bug reports: $e',
        tag: 'BugReportSharer',
        metadata: {'reportIds': reportIds},
      );
      rethrow;
    }
  }

  /// Share all bug reports
  static Future<void> shareAllReports({
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final content = BugReportManager.instance.exportAllReports();
      final shareSubject = subject ?? 'All Bug Reports Export';

      await Share.share(
        content,
        subject: shareSubject,
        sharePositionOrigin: sharePositionOrigin,
      );

      BugReportLogger.instance.info(
        'All bug reports shared',
        tag: 'BugReportSharer',
        metadata: {
          'totalReports': BugReportManager.instance.reports.length,
        },
      );
    } catch (e) {
      BugReportLogger.instance.error(
        'Failed to share all bug reports: $e',
        tag: 'BugReportSharer',
      );
      rethrow;
    }
  }

  /// Export bug report to a file and share
  static Future<void> exportAndShareBugReport(
    String reportId, {
    String? fileName,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final report = BugReportManager.instance.getReportById(reportId);
      if (report == null) {
        throw Exception('Bug report not found: $reportId');
      }

      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/${fileName ?? 'bug_report_${report.id}.txt'}',
      );

      await file.writeAsString(report.toFormattedString());

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'Bug Report: ${report.title}',
        sharePositionOrigin: sharePositionOrigin,
      );

      BugReportLogger.instance.info(
        'Bug report exported and shared as file',
        tag: 'BugReportSharer',
        metadata: {
          'reportId': reportId,
          'filePath': file.path,
        },
      );
    } catch (e) {
      BugReportLogger.instance.error(
        'Failed to export and share bug report: $e',
        tag: 'BugReportSharer',
        metadata: {'reportId': reportId},
      );
      rethrow;
    }
  }

  /// Export logs and share
  static Future<void> shareApplicationLogs({
    String? fileName,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final logs = BugReportLogger.instance.exportLogs();
      
      if (logs.isEmpty) {
        throw Exception('No logs available to share');
      }

      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/${fileName ?? 'app_logs_${DateTime.now().millisecondsSinceEpoch}.txt'}',
      );

      await file.writeAsString(logs);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'Application Logs',
        sharePositionOrigin: sharePositionOrigin,
      );

      BugReportLogger.instance.info(
        'Application logs shared',
        tag: 'BugReportSharer',
        metadata: {'filePath': file.path},
      );
    } catch (e) {
      BugReportLogger.instance.error(
        'Failed to share application logs: $e',
        tag: 'BugReportSharer',
      );
      rethrow;
    }
  }

  /// Share bug report statistics
  static Future<void> shareStatistics({
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final stats = BugReportManager.instance.getStatistics();
      
      final buffer = StringBuffer();
      buffer.writeln('📊 BUG REPORT STATISTICS');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('=' * 40);
      buffer.writeln();
      
      buffer.writeln('📈 OVERVIEW');
      buffer.writeln('Total Reports: ${stats['totalReports']}');
      buffer.writeln('Recent Reports (7 days): ${stats['recentReports']}');
      buffer.writeln();
      
      buffer.writeln('🚨 BY SEVERITY');
      final bySeverity = stats['bySeverity'] as Map<String, int>;
      for (final entry in bySeverity.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
      buffer.writeln();
      
      buffer.writeln('🏷️ BY TAG');
      final byTag = stats['byTag'] as Map<String, int>;
      if (byTag.isNotEmpty) {
        for (final entry in byTag.entries) {
          buffer.writeln('${entry.key}: ${entry.value}');
        }
      } else {
        buffer.writeln('No tags found');
      }

      await Share.share(
        buffer.toString(),
        subject: subject ?? 'Bug Report Statistics',
        sharePositionOrigin: sharePositionOrigin,
      );

      BugReportLogger.instance.info(
        'Bug report statistics shared',
        tag: 'BugReportSharer',
      );
    } catch (e) {
      BugReportLogger.instance.error(
        'Failed to share statistics: $e',
        tag: 'BugReportSharer',
      );
      rethrow;
    }
  }
}
