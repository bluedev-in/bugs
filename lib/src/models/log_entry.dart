import 'package:intl/intl.dart';
import 'log_level.dart';

/// Represents a single log entry
class LogEntry {
  /// The timestamp when the log was created
  final DateTime timestamp;
  
  /// The log level
  final LogLevel level;
  
  /// The log message
  final String message;
  
  /// Additional context or metadata
  final Map<String, dynamic>? metadata;
  
  /// The source/tag where the log originated from
  final String? tag;
  
  /// Stack trace if available (usually for errors)
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.metadata,
    this.tag,
    this.stackTrace,
  });

  /// Creates a LogEntry with current timestamp
  factory LogEntry.now({
    required LogLevel level,
    required String message,
    Map<String, dynamic>? metadata,
    String? tag,
    StackTrace? stackTrace,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      metadata: metadata,
      tag: tag,
      stackTrace: stackTrace,
    );
  }

  /// Converts the log entry to a formatted string
  String toFormattedString() {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final timeStr = dateFormatter.format(timestamp);
    final levelStr = level.name.padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';
    
    var result = '$timeStr $levelStr $tagStr$message';
    
    if (metadata != null && metadata!.isNotEmpty) {
      result += '\n  Metadata: $metadata';
    }
    
    if (stackTrace != null) {
      result += '\n  StackTrace:\n${stackTrace.toString()}';
    }
    
    return result;
  }

  /// Converts the log entry to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'metadata': metadata,
      'tag': tag,
      'stackTrace': stackTrace?.toString(),
    };
  }

  /// Creates a LogEntry from a JSON map
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere(
        (level) => level.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      tag: json['tag'],
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace']) 
          : null,
    );
  }

  @override
  String toString() => toFormattedString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogEntry &&
        other.timestamp == timestamp &&
        other.level == level &&
        other.message == message &&
        other.tag == tag;
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, level, message, tag);
  }
}
