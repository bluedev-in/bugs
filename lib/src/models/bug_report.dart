import 'package:intl/intl.dart';
import 'device_info.dart';
import 'log_entry.dart';

/// Bug report severity levels
enum BugSeverity {
  /// Low priority - minor issues
  low,
  
  /// Medium priority - noticeable issues
  medium,
  
  /// High priority - major issues
  high,
  
  /// Critical priority - blocking issues
  critical;

  String get name {
    switch (this) {
      case BugSeverity.low:
        return 'Low';
      case BugSeverity.medium:
        return 'Medium';
      case BugSeverity.high:
        return 'High';
      case BugSeverity.critical:
        return 'Critical';
    }
  }
}

/// Represents a comprehensive bug report
class BugReport {
  /// Unique identifier for the bug report
  final String id;
  
  /// Bug title/summary
  final String title;
  
  /// Detailed description of the bug
  final String description;
  
  /// Severity level
  final BugSeverity severity;
  
  /// Steps to reproduce the bug
  final List<String> stepsToReproduce;
  
  /// Expected behavior
  final String? expectedBehavior;
  
  /// Actual behavior
  final String? actualBehavior;
  
  /// Device and app information
  final DeviceInfo deviceInfo;
  
  /// Associated log entries
  final List<LogEntry> logs;
  
  /// Screenshots or attachments (file paths)
  final List<String> attachments;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;
  
  /// Timestamp when the bug report was created
  final DateTime timestamp;
  
  /// User who reported the bug
  final String? reportedBy;
  
  /// Tags for categorization
  final List<String> tags;

  const BugReport({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.stepsToReproduce,
    required this.deviceInfo,
    required this.logs,
    required this.timestamp,
    this.expectedBehavior,
    this.actualBehavior,
    this.attachments = const [],
    this.metadata,
    this.reportedBy,
    this.tags = const [],
  });

  /// Creates a bug report with current timestamp and generated ID
  factory BugReport.create({
    required String title,
    required String description,
    required BugSeverity severity,
    required List<String> stepsToReproduce,
    required DeviceInfo deviceInfo,
    required List<LogEntry> logs,
    String? expectedBehavior,
    String? actualBehavior,
    List<String> attachments = const [],
    Map<String, dynamic>? metadata,
    String? reportedBy,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    final id = 'bug_${now.millisecondsSinceEpoch}';
    
    return BugReport(
      id: id,
      title: title,
      description: description,
      severity: severity,
      stepsToReproduce: stepsToReproduce,
      deviceInfo: deviceInfo,
      logs: logs,
      timestamp: now,
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      attachments: attachments,
      metadata: metadata,
      reportedBy: reportedBy,
      tags: tags,
    );
  }

  /// Converts to a formatted string for sharing
  String toFormattedString() {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final buffer = StringBuffer();
    
    buffer.writeln('🐛 BUG REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln('ID: $id');
    buffer.writeln('Title: $title');
    buffer.writeln('Severity: ${severity.name}');
    buffer.writeln('Reported: ${dateFormatter.format(timestamp)}');
    if (reportedBy != null) buffer.writeln('Reporter: $reportedBy');
    if (tags.isNotEmpty) buffer.writeln('Tags: ${tags.join(', ')}');
    buffer.writeln();
    
    buffer.writeln('📝 DESCRIPTION');
    buffer.writeln('-' * 20);
    buffer.writeln(description);
    buffer.writeln();
    
    if (stepsToReproduce.isNotEmpty) {
      buffer.writeln('🔄 STEPS TO REPRODUCE');
      buffer.writeln('-' * 20);
      for (int i = 0; i < stepsToReproduce.length; i++) {
        buffer.writeln('${i + 1}. ${stepsToReproduce[i]}');
      }
      buffer.writeln();
    }
    
    if (expectedBehavior != null) {
      buffer.writeln('✅ EXPECTED BEHAVIOR');
      buffer.writeln('-' * 20);
      buffer.writeln(expectedBehavior);
      buffer.writeln();
    }
    
    if (actualBehavior != null) {
      buffer.writeln('❌ ACTUAL BEHAVIOR');
      buffer.writeln('-' * 20);
      buffer.writeln(actualBehavior);
      buffer.writeln();
    }
    
    buffer.writeln('📱 DEVICE INFORMATION');
    buffer.writeln('-' * 20);
    buffer.writeln('Device: ${deviceInfo.deviceModel ?? 'Unknown'}');
    buffer.writeln('OS: ${deviceInfo.operatingSystem ?? 'Unknown'} ${deviceInfo.osVersion ?? ''}');
    buffer.writeln('App: ${deviceInfo.appName ?? 'Unknown'} v${deviceInfo.appVersion ?? 'Unknown'}');
    buffer.writeln('Build: ${deviceInfo.buildNumber ?? 'Unknown'}');
    buffer.writeln();
    
    if (logs.isNotEmpty) {
      buffer.writeln('📋 RECENT LOGS');
      buffer.writeln('-' * 20);
      final recentLogs = logs.length > 10 ? logs.sublist(logs.length - 10) : logs;
      for (final log in recentLogs) {
        buffer.writeln(log.toFormattedString());
      }
      buffer.writeln();
    }
    
    if (attachments.isNotEmpty) {
      buffer.writeln('📎 ATTACHMENTS');
      buffer.writeln('-' * 20);
      for (final attachment in attachments) {
        buffer.writeln('• $attachment');
      }
      buffer.writeln();
    }
    
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.writeln('🔧 ADDITIONAL INFO');
      buffer.writeln('-' * 20);
      metadata!.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    }
    
    return buffer.toString();
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'stepsToReproduce': stepsToReproduce,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'deviceInfo': deviceInfo.toJson(),
      'logs': logs.map((log) => log.toJson()).toList(),
      'attachments': attachments,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'reportedBy': reportedBy,
      'tags': tags,
    };
  }

  /// Creates BugReport from JSON map
  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: BugSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => BugSeverity.medium,
      ),
      stepsToReproduce: List<String>.from(json['stepsToReproduce'] ?? []),
      expectedBehavior: json['expectedBehavior'],
      actualBehavior: json['actualBehavior'],
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo']),
      logs: (json['logs'] as List<dynamic>?)
          ?.map((logJson) => LogEntry.fromJson(logJson))
          .toList() ?? [],
      attachments: List<String>.from(json['attachments'] ?? []),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      reportedBy: json['reportedBy'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// Creates a copy with updated fields
  BugReport copyWith({
    String? title,
    String? description,
    BugSeverity? severity,
    List<String>? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    List<LogEntry>? logs,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    String? reportedBy,
    List<String>? tags,
  }) {
    return BugReport(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      stepsToReproduce: stepsToReproduce ?? this.stepsToReproduce,
      deviceInfo: deviceInfo,
      logs: logs ?? this.logs,
      timestamp: timestamp,
      expectedBehavior: expectedBehavior ?? this.expectedBehavior,
      actualBehavior: actualBehavior ?? this.actualBehavior,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      reportedBy: reportedBy ?? this.reportedBy,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() => toFormattedString();
}
