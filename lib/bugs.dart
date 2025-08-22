/// A comprehensive bug report and logger package for Flutter applications.
/// 
/// This library provides tools for logging, bug reporting, error handling,
/// and sharing bug reports in Flutter applications.
// library bugreport;

// Core components
export 'src/core/logger.dart';
export 'src/core/bug_report_manager.dart';

// Models
export 'src/models/log_level.dart';
export 'src/models/log_entry.dart';
export 'src/models/device_info.dart';
export 'src/models/bug_report.dart';

// Utilities
export 'src/utils/error_handler.dart';
export 'src/utils/bug_report_sharer.dart';

// Widgets
export 'src/widgets/bug_report_form.dart';
export 'src/widgets/bug_report_list.dart';

// Import for internal use
import 'src/core/logger.dart';
import 'src/core/bug_report_manager.dart';
import 'src/models/log_level.dart';
import 'src/models/log_entry.dart';
import 'src/models/bug_report.dart' as bug_report_model;
import 'src/utils/error_handler.dart';

/// Main class providing convenient access to bug reporting functionality
class BugReportSystem {
  /// Initialize the bug report system
  /// 
  /// This should be called early in your app initialization, preferably
  /// in your main() function before runApp().
  /// 
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   
  ///   // Initialize bug reporting
  ///   await BugReportSystem.initialize(
  ///     loggerConfig: LoggerConfig(
  ///       minLogLevel: LogLevel.debug,
  ///       enableFileLogging: true,
  ///     ),
  ///     bugReportConfig: BugReportConfig(
  ///       autoIncludeLogs: true,
  ///       maxLogsPerReport: 100,
  ///     ),
  ///     enableGlobalErrorHandling: true,
  ///   );
  ///   
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize({
    LoggerConfig? loggerConfig,
    BugReportConfig? bugReportConfig,
    bool enableGlobalErrorHandling = false,
    String? globalErrorTag,
  }) async {
    // Initialize logger
    await BugReportLogger.instance.initialize(loggerConfig);
    
    // Initialize bug report manager
    await BugReportManager.instance.initialize(bugReportConfig);
    
    // Set up global error handling if requested
    if (enableGlobalErrorHandling) {
      GlobalErrorHandler.initialize(
        captureFlutterErrors: true,
        capturePlatformErrors: true,
        tag: globalErrorTag,
      );
    }
    
    BugReportLogger.instance.info(
      'Bug report system initialized',
      tag: 'BugReportSystem',
      metadata: {
        'loggerEnabled': true,
        'bugReportManagerEnabled': true,
        'globalErrorHandling': enableGlobalErrorHandling,
      },
    );
  }

  /// Get the logger instance
  static BugReportLogger get logger => BugReportLogger.instance;

  /// Get the bug report manager instance
  static BugReportManager get manager => BugReportManager.instance;

  /// Quick logging methods
  static void debug(String message, {String? tag, Map<String, dynamic>? metadata}) {
    logger.debug(message, tag: tag, metadata: metadata);
  }

  static void info(String message, {String? tag, Map<String, dynamic>? metadata}) {
    logger.info(message, tag: tag, metadata: metadata);
  }

  static void warning(String message, {String? tag, Map<String, dynamic>? metadata}) {
    logger.warning(message, tag: tag, metadata: metadata);
  }

  static void error(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    logger.error(message, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  static void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    logger.fatal(message, tag: tag, metadata: metadata, stackTrace: stackTrace);
  }

  /// Report an error manually
  static void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    LogLevel level = LogLevel.error,
    String? tag,
  }) {
    ErrorReporter.reportError(
      error,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
      level: level,
      tag: tag,
    );
  }

  /// Handle network errors
  static void reportNetworkError(
    Object error, {
    String? url,
    String? method,
    int? statusCode,
    Map<String, dynamic>? requestData,
    String? tag,
  }) {
    NetworkErrorHandler.handleNetworkError(
      error,
      url: url,
      method: method,
      statusCode: statusCode,
      requestData: requestData,
      tag: tag,
    );
  }

  /// Monitor performance of operations
  static T timeOperation<T>(
    String operation,
    T Function() function, {
    Duration? warningThreshold,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    return PerformanceMonitor.timeFunction(
      operation,
      function,
      warningThreshold: warningThreshold,
      tag: tag,
      metadata: metadata,
    );
  }

  /// Monitor performance of async operations
  static Future<T> timeAsyncOperation<T>(
    String operation,
    Future<T> Function() function, {
    Duration? warningThreshold,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    return PerformanceMonitor.timeAsyncFunction(
      operation,
      function,
      warningThreshold: warningThreshold,
      tag: tag,
      metadata: metadata,
    );
  }

  /// Create a bug report programmatically
  static Future<bug_report_model.BugReport> create({
    required String title,
    required String description,
    required bug_report_model.BugSeverity severity,
    required List<String> stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    List<String> attachments = const [],
    Map<String, dynamic>? metadata,
    String? reportedBy,
    List<String>? tags,
    List<LogEntry>? customLogs,
  }) {
    return manager.createBugReport(
      title: title,
      description: description,
      severity: severity,
      stepsToReproduce: stepsToReproduce,
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      attachments: attachments,
      metadata: metadata,
      reportedBy: reportedBy,
      tags: tags,
      customLogs: customLogs,
    );
  }

  /// Get all bug reports
  static List<bug_report_model.BugReport> get allReports => manager.reports;

  /// Get recent logs
  static List<LogEntry> getRecentLogs([int count = 50]) {
    return logger.getRecentLogs(count);
  }

  /// Export logs as string
  static String exportLogs() {
    return logger.exportLogs();
  }

  /// Get bug report statistics
  static Map<String, dynamic> getStatistics() {
    return manager.getStatistics();
  }

  /// Dispose of resources (call this when your app is shutting down)
  static void dispose() {
    GlobalErrorHandler.restore();
    logger.dispose();
    manager.dispose();
  }
}
