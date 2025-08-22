import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import '../models/log_level.dart';

/// Global error handler for Flutter applications
class GlobalErrorHandler {
  static bool _initialized = false;
  static FlutterExceptionHandler? _originalOnError;
  static ErrorCallback? _originalPlatformDispatcher;

  /// Initialize global error handling
  static void initialize({
    bool captureFlutterErrors = true,
    bool capturePlatformErrors = true,
    String? tag,
  }) {
    if (_initialized) return;

    final logger = BugReportLogger.instance;
    final errorTag = tag ?? 'GlobalErrorHandler';

    if (captureFlutterErrors) {
      // Store original handler
      _originalOnError = FlutterError.onError;
      
      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        logger.error(
          'Flutter Error: ${details.exception}',
          tag: errorTag,
          metadata: {
            'library': details.library,
            'context': details.context?.toString(),
            'informationCollector': details.informationCollector?.toString(),
          },
          stackTrace: details.stack,
        );

        // Call original handler if it exists
        _originalOnError?.call(details);
      };
    }

    if (capturePlatformErrors) {
      // Store original handler
      _originalPlatformDispatcher = PlatformDispatcher.instance.onError;
      
      // Set up platform error handling
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        logger.fatal(
          'Platform Error: $error',
          tag: errorTag,
          stackTrace: stack,
        );

        // Call original handler if it exists
        if (_originalPlatformDispatcher != null) {
          return _originalPlatformDispatcher!(error, stack);
        }
        return true;
      };
    }

    _initialized = true;
    
    logger.info(
      'Global error handler initialized',
      tag: errorTag,
      metadata: {
        'captureFlutterErrors': captureFlutterErrors,
        'capturePlatformErrors': capturePlatformErrors,
      },
    );
  }

  /// Restore original error handlers
  static void restore() {
    if (!_initialized) return;

    if (_originalOnError != null) {
      FlutterError.onError = _originalOnError;
      _originalOnError = null;
    }

    if (_originalPlatformDispatcher != null) {
      PlatformDispatcher.instance.onError = _originalPlatformDispatcher;
      _originalPlatformDispatcher = null;
    }

    _initialized = false;
    
    BugReportLogger.instance.info(
      'Global error handler restored',
      tag: 'GlobalErrorHandler',
    );
  }

  /// Check if error handling is initialized
  static bool get isInitialized => _initialized;
}

/// Zone-based error handling
class ZoneErrorHandler {
  /// Run the app in a error-capturing zone
  static void runAppInZone(
    void Function() app, {
    String? tag,
    void Function(Object error, StackTrace stack)? onError,
  }) {
    final logger = BugReportLogger.instance;
    final errorTag = tag ?? 'ZoneErrorHandler';

    runZonedGuarded(
      app,
      (Object error, StackTrace stack) {
        logger.fatal(
          'Zone Error: $error',
          tag: errorTag,
          stackTrace: stack,
        );

        // Call custom error handler if provided
        onError?.call(error, stack);
      },
    );

    logger.info(
      'App running in error-capturing zone',
      tag: errorTag,
    );
  }
}

/// Utility for manual error reporting
class ErrorReporter {
  /// Report an error manually
  static void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    LogLevel level = LogLevel.error,
    String? tag,
  }) {
    final logger = BugReportLogger.instance;
    
    final errorMessage = context != null 
        ? '$context: $error'
        : error.toString();

    logger.log(
      level: level,
      message: errorMessage,
      tag: tag ?? 'ErrorReporter',
      metadata: metadata,
      stackTrace: stackTrace,
    );
  }

  /// Report a caught exception
  static void reportException(
    Exception exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    String? tag,
  }) {
    reportError(
      exception,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
      level: LogLevel.error,
      tag: tag,
    );
  }

  /// Report a critical error
  static void reportCriticalError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    String? tag,
  }) {
    reportError(
      error,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
      level: LogLevel.fatal,
      tag: tag,
    );
  }
}

/// Network error utilities
class NetworkErrorHandler {
  /// Handle and log network errors
  static void handleNetworkError(
    Object error, {
    String? url,
    String? method,
    int? statusCode,
    Map<String, dynamic>? requestData,
    String? tag,
  }) {
    final logger = BugReportLogger.instance;
    
    logger.error(
      'Network Error: $error',
      tag: tag ?? 'NetworkError',
      metadata: {
        'url': url,
        'method': method,
        'statusCode': statusCode,
        'requestData': requestData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Handle timeout errors specifically
  static void handleTimeoutError(
    String operation, {
    Duration? timeout,
    String? url,
    String? tag,
  }) {
    final logger = BugReportLogger.instance;
    
    logger.warning(
      'Timeout Error: $operation timed out',
      tag: tag ?? 'TimeoutError',
      metadata: {
        'operation': operation,
        'timeout': timeout?.inMilliseconds,
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};

  /// Start timing an operation
  static void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End timing and log if it exceeds threshold
  static void endTimer(
    String operation, {
    Duration? warningThreshold,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    final threshold = warningThreshold ?? const Duration(seconds: 1);

    if (duration > threshold) {
      BugReportLogger.instance.warning(
        'Slow Operation: $operation took ${duration.inMilliseconds}ms',
        tag: tag ?? 'Performance',
        metadata: {
          'operation': operation,
          'duration_ms': duration.inMilliseconds,
          'threshold_ms': threshold.inMilliseconds,
          ...?metadata,
        },
      );
    } else {
      BugReportLogger.instance.debug(
        'Operation completed: $operation (${duration.inMilliseconds}ms)',
        tag: tag ?? 'Performance',
        metadata: {
          'operation': operation,
          'duration_ms': duration.inMilliseconds,
          ...?metadata,
        },
      );
    }
  }

  /// Time a function execution
  static T timeFunction<T>(
    String operation,
    T Function() function, {
    Duration? warningThreshold,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    startTimer(operation);
    try {
      return function();
    } finally {
      endTimer(
        operation,
        warningThreshold: warningThreshold,
        tag: tag,
        metadata: metadata,
      );
    }
  }

  /// Time an async function execution
  static Future<T> timeAsyncFunction<T>(
    String operation,
    Future<T> Function() function, {
    Duration? warningThreshold,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    startTimer(operation);
    try {
      return await function();
    } finally {
      endTimer(
        operation,
        warningThreshold: warningThreshold,
        tag: tag,
        metadata: metadata,
      );
    }
  }
}
