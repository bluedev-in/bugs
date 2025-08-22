/// Enumeration for different log levels
enum LogLevel {
  /// Debug level - for detailed debugging information
  debug,
  
  /// Info level - for general information
  info,
  
  /// Warning level - for warning messages
  warning,
  
  /// Error level - for error messages
  error,
  
  /// Fatal level - for critical errors
  fatal;

  /// Returns the string representation of the log level
  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  /// Returns the priority of the log level (higher number = higher priority)
  int get priority {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
      case LogLevel.fatal:
        return 4;
    }
  }
}
