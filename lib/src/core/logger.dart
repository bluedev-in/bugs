import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/log_entry.dart';
import '../models/log_level.dart';

/// Configuration for the logger
class LoggerConfig {
  /// Maximum number of log entries to keep in memory
  final int maxMemoryLogs;
  
  /// Maximum number of log entries to keep in file storage
  final int maxFileLogs;
  
  /// Minimum log level to record
  final LogLevel minLogLevel;
  
  /// Whether to write logs to file
  final bool enableFileLogging;
  
  /// Whether to print logs to console
  final bool enableConsoleLogging;
  
  /// Custom log file name (optional)
  final String? logFileName;
  
  /// Whether to include stack traces for errors automatically
  final bool autoStackTrace;

  const LoggerConfig({
    this.maxMemoryLogs = 1000,
    this.maxFileLogs = 5000,
    this.minLogLevel = LogLevel.debug,
    this.enableFileLogging = true,
    this.enableConsoleLogging = true,
    this.logFileName,
    this.autoStackTrace = true,
  });
}

/// Main logger class for the application
class BugReportLogger {
  static BugReportLogger? _instance;
  
  /// Get the singleton instance
  static BugReportLogger get instance => _instance ??= BugReportLogger._();
  
  BugReportLogger._();

  LoggerConfig _config = const LoggerConfig();
  final List<LogEntry> _memoryLogs = [];
  final StreamController<LogEntry> _logStreamController = 
      StreamController<LogEntry>.broadcast();
  
  File? _logFile;
  bool _initialized = false;

  /// Stream of log entries
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Current configuration
  LoggerConfig get config => _config;

  /// All logs currently in memory
  List<LogEntry> get memoryLogs => List.unmodifiable(_memoryLogs);

  /// Initialize the logger with configuration
  Future<void> initialize([LoggerConfig? config]) async {
    if (_initialized) return;
    
    _config = config ?? _config;
    
    if (_config.enableFileLogging) {
      await _initializeFileLogging();
    }
    
    _initialized = true;
  }

  /// Initialize file logging
  Future<void> _initializeFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final fileName = _config.logFileName ?? 'app_logs.txt';
      _logFile = File('${logDir.path}/$fileName');
      
      // Load existing logs from file
      if (await _logFile!.exists()) {
        await _loadLogsFromFile();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize file logging: $e');
      }
    }
  }

  /// Load existing logs from file
  Future<void> _loadLogsFromFile() async {
    if (_logFile == null || !await _logFile!.exists()) return;
    
    try {
      final content = await _logFile!.readAsString();
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
      
      for (final line in lines) {
        try {
          final json = jsonDecode(line);
          final logEntry = LogEntry.fromJson(json);
          _memoryLogs.add(logEntry);
        } catch (e) {
          // Skip invalid log entries
        }
      }
      
      // Keep only the most recent logs
      if (_memoryLogs.length > _config.maxMemoryLogs) {
        _memoryLogs.removeRange(
          0, 
          _memoryLogs.length - _config.maxMemoryLogs,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load logs from file: $e');
      }
    }
  }

  /// Log a message with the specified level
  void log({
    required LogLevel level,
    required String message,
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    if (!_initialized) {
      initialize();
    }
    
    if (level.priority < _config.minLogLevel.priority) {
      return;
    }

    // Auto-capture stack trace for errors if enabled
    StackTrace? finalStackTrace = stackTrace;
    if (finalStackTrace == null && 
        _config.autoStackTrace && 
        (level == LogLevel.error || level == LogLevel.fatal)) {
      finalStackTrace = StackTrace.current;
    }

    final logEntry = LogEntry.now(
      level: level,
      message: message,
      tag: tag,
      metadata: metadata,
      stackTrace: finalStackTrace,
    );

    _addLogEntry(logEntry);
  }

  /// Add a log entry to storage and streams
  void _addLogEntry(LogEntry logEntry) {
    // Add to memory logs
    _memoryLogs.add(logEntry);
    
    // Maintain memory limit
    if (_memoryLogs.length > _config.maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }

    // Console logging
    if (_config.enableConsoleLogging) {
      if (kDebugMode) {
        print(logEntry.toFormattedString());
      }
    }

    // File logging
    if (_config.enableFileLogging && _logFile != null) {
      _writeLogToFile(logEntry);
    }

    // Broadcast to stream
    _logStreamController.add(logEntry);
  }

  /// Write log entry to file
  void _writeLogToFile(LogEntry logEntry) {
    if (_logFile == null) return;
    
    try {
      final logJson = jsonEncode(logEntry.toJson());
      _logFile!.writeAsStringSync('$logJson\n', mode: FileMode.append);
      
      // TODO: Implement log file rotation based on _config.maxFileLogs
    } catch (e) {
      if (kDebugMode) {
        print('Failed to write log to file: $e');
      }
    }
  }

  /// Debug level logging
  void debug(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(level: LogLevel.debug, message: message, tag: tag, metadata: metadata);
  }

  /// Info level logging
  void info(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(level: LogLevel.info, message: message, tag: tag, metadata: metadata);
  }

  /// Warning level logging
  void warning(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(level: LogLevel.warning, message: message, tag: tag, metadata: metadata);
  }

  /// Error level logging
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.error,
      message: message,
      tag: tag,
      metadata: metadata,
      stackTrace: stackTrace,
    );
  }

  /// Fatal level logging
  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.fatal,
      message: message,
      tag: tag,
      metadata: metadata,
      stackTrace: stackTrace,
    );
  }

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _memoryLogs.where((log) => log.level == level).toList();
  }

  /// Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _memoryLogs.where((log) => log.tag == tag).toList();
  }

  /// Get recent logs (last n entries)
  List<LogEntry> getRecentLogs([int count = 50]) {
    if (_memoryLogs.length <= count) {
      return List.from(_memoryLogs);
    }
    return _memoryLogs.sublist(_memoryLogs.length - count);
  }

  /// Clear all logs from memory and optionally from file
  Future<void> clearLogs({bool clearFile = false}) async {
    _memoryLogs.clear();
    
    if (clearFile && _logFile != null) {
      try {
        if (await _logFile!.exists()) {
          await _logFile!.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to clear log file: $e');
        }
      }
    }
  }

  /// Export logs to a string
  String exportLogs() {
    final buffer = StringBuffer();
    for (final log in _memoryLogs) {
      buffer.writeln(log.toFormattedString());
    }
    return buffer.toString();
  }

  /// Get the log file path
  String? get logFilePath => _logFile?.path;

  /// Dispose of resources
  void dispose() {
    _logStreamController.close();
    _instance = null;
    _initialized = false;
  }
}
