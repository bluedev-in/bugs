import 'package:flutter_test/flutter_test.dart';
import 'package:bugs/bugs.dart';

void main() {
  group('BugReportSystem Tests', () {
    setUp(() async {
      // Initialize the bug report system for testing
      await BugReportSystem.initialize(
        loggerConfig: LoggerConfig(
          minLogLevel: LogLevel.debug,
          enableFileLogging: false, // Disable file logging for tests
          enableConsoleLogging: false, // Disable console logging for tests
        ),
        bugReportConfig: BugReportConfig(
          autoIncludeLogs: true,
          maxLogsPerReport: 10,
        ),
        enableGlobalErrorHandling: false, // Disable for tests
      );
    });

    tearDown(() {
      // Clean up after each test
      BugReportSystem.dispose();
    });

    test('logger should log messages correctly', () {
      // Test debug logging
      BugReportSystem.debug('Debug message', tag: 'Test');
      
      // Test info logging
      BugReportSystem.info('Info message', tag: 'Test');
      
      // Test warning logging
      BugReportSystem.warning('Warning message', tag: 'Test');
      
      // Test error logging
      BugReportSystem.error('Error message', tag: 'Test');
      
      // Test fatal logging
      BugReportSystem.fatal('Fatal message', tag: 'Test');
      
      // Verify logs were recorded
      final recentLogs = BugReportSystem.getRecentLogs(10);
      expect(recentLogs.length, equals(5));
      
      // Check log levels
      expect(recentLogs[0].level, equals(LogLevel.debug));
      expect(recentLogs[1].level, equals(LogLevel.info));
      expect(recentLogs[2].level, equals(LogLevel.warning));
      expect(recentLogs[3].level, equals(LogLevel.error));
      expect(recentLogs[4].level, equals(LogLevel.fatal));
    });

    test('should create bug reports', () async {
      final bugReport = await BugReportSystem.create(
        title: 'Test Bug',
        description: 'This is a test bug description',
        severity: BugSeverity.medium,
        stepsToReproduce: [
          'Step 1: Do something',
          'Step 2: Observe issue',
        ],
        expectedBehavior: 'Should work correctly',
        actualBehavior: 'Does not work as expected',
        tags: ['test', 'automation'],
        reportedBy: 'Test Suite',
      );

      expect(bugReport.title, equals('Test Bug'));
      expect(bugReport.severity, equals(BugSeverity.medium));
      expect(bugReport.stepsToReproduce.length, equals(2));
      expect(bugReport.tags.contains('test'), isTrue);
      expect(bugReport.reportedBy, equals('Test Suite'));
      
      // Verify it was added to the manager
      final allReports = BugReportSystem.allReports;
      expect(allReports.length, equals(1));
      expect(allReports.first.id, equals(bugReport.id));
    });

    test('should handle error reporting', () {
      final testError = Exception('Test error');
      final testStackTrace = StackTrace.current;
      
      BugReportSystem.reportError(
        testError,
        stackTrace: testStackTrace,
        context: 'Test context',
        metadata: {'test': true},
        tag: 'ErrorTest',
      );
      
      final recentLogs = BugReportSystem.getRecentLogs(1);
      expect(recentLogs.length, equals(1));
      expect(recentLogs.first.level, equals(LogLevel.error));
      expect(recentLogs.first.message.contains('Test error'), isTrue);
      expect(recentLogs.first.tag, equals('ErrorTest'));
    });

    test('should handle network error reporting', () {
      BugReportSystem.reportNetworkError(
        'Connection timeout',
        url: 'https://test.com/api',
        method: 'GET',
        statusCode: 408,
        requestData: {'test': 'data'},
        tag: 'NetworkTest',
      );
      
      final recentLogs = BugReportSystem.getRecentLogs(1);
      expect(recentLogs.length, equals(1));
      expect(recentLogs.first.level, equals(LogLevel.error));
      expect(recentLogs.first.message.contains('Connection timeout'), isTrue);
      expect(recentLogs.first.tag, equals('NetworkTest'));
      expect(recentLogs.first.metadata?['url'], equals('https://test.com/api'));
    });

    test('should measure operation performance', () {
      final result = BugReportSystem.timeOperation(
        'Test Operation',
        () {
          // Simulate some work
          for (int i = 0; i < 1000; i++) {
            // Busy work
          }
          return 'completed';
        },
        tag: 'PerformanceTest',
      );
      
      expect(result, equals('completed'));
      
      final recentLogs = BugReportSystem.getRecentLogs(1);
      expect(recentLogs.length, equals(1));
      expect(recentLogs.first.message.contains('Test Operation'), isTrue);
      expect(recentLogs.first.tag, equals('PerformanceTest'));
    });

    test('should export logs', () {
      // Add some test logs
      BugReportSystem.info('Log 1', tag: 'Export');
      BugReportSystem.warning('Log 2', tag: 'Export');
      BugReportSystem.error('Log 3', tag: 'Export');
      
      final exportedLogs = BugReportSystem.exportLogs();
      expect(exportedLogs.isNotEmpty, isTrue);
      expect(exportedLogs.contains('Log 1'), isTrue);
      expect(exportedLogs.contains('Log 2'), isTrue);
      expect(exportedLogs.contains('Log 3'), isTrue);
    });

    test('should provide statistics', () {
      // Create some test data
      BugReportSystem.info('Test log 1');
      BugReportSystem.error('Test error 1');
      
      final stats = BugReportSystem.getStatistics();
      expect(stats['totalReports'], isA<int>());
      expect(stats['recentReports'], isA<int>());
      expect(stats['bySeverity'], isA<Map>());
      expect(stats['byTag'], isA<Map>());
    });
  });

  group('LogLevel Tests', () {
    test('should have correct priority order', () {
      expect(LogLevel.debug.priority, equals(0));
      expect(LogLevel.info.priority, equals(1));
      expect(LogLevel.warning.priority, equals(2));
      expect(LogLevel.error.priority, equals(3));
      expect(LogLevel.fatal.priority, equals(4));
    });

    test('should have correct string names', () {
      expect(LogLevel.debug.name, equals('DEBUG'));
      expect(LogLevel.info.name, equals('INFO'));
      expect(LogLevel.warning.name, equals('WARNING'));
      expect(LogLevel.error.name, equals('ERROR'));
      expect(LogLevel.fatal.name, equals('FATAL'));
    });
  });

  group('BugSeverity Tests', () {
    test('should have correct string names', () {
      expect(BugSeverity.low.name, equals('Low'));
      expect(BugSeverity.medium.name, equals('Medium'));
      expect(BugSeverity.high.name, equals('High'));
      expect(BugSeverity.critical.name, equals('Critical'));
    });
  });

  group('LogEntry Tests', () {
    test('should create log entry with current timestamp', () {
      final entry = LogEntry.now(
        level: LogLevel.info,
        message: 'Test message',
        tag: 'Test',
        metadata: {'key': 'value'},
      );

      expect(entry.level, equals(LogLevel.info));
      expect(entry.message, equals('Test message'));
      expect(entry.tag, equals('Test'));
      expect(entry.metadata?['key'], equals('value'));
      expect(entry.timestamp.isBefore(DateTime.now()), isTrue);
    });

    test('should convert to and from JSON', () {
      final originalEntry = LogEntry.now(
        level: LogLevel.warning,
        message: 'Test warning',
        tag: 'JsonTest',
        metadata: {'number': 42, 'boolean': true},
      );

      final json = originalEntry.toJson();
      final restoredEntry = LogEntry.fromJson(json);

      expect(restoredEntry.level, equals(originalEntry.level));
      expect(restoredEntry.message, equals(originalEntry.message));
      expect(restoredEntry.tag, equals(originalEntry.tag));
      expect(restoredEntry.metadata?['number'], equals(42));
      expect(restoredEntry.metadata?['boolean'], equals(true));
    });

    test('should format correctly', () {
      final entry = LogEntry(
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        level: LogLevel.error,
        message: 'Test error message',
        tag: 'Format',
        metadata: {'error_code': 500},
      );

      final formatted = entry.toFormattedString();
      expect(formatted.contains('ERROR'), isTrue);
      expect(formatted.contains('Test error message'), isTrue);
      expect(formatted.contains('[Format]'), isTrue);
      expect(formatted.contains('error_code'), isTrue);
    });
  });
}
