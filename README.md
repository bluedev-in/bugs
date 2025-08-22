# Bug Report & Logger Package for Flutter

A comprehensive bug reporting and logging solution for Flutter applications. This package provides powerful tools for logging, error handling, bug report creation, and sharing functionality.

## Features

### 🔍 **Advanced Logging System**
- Multiple log levels (Debug, Info, Warning, Error, Fatal)
- File and console logging support
- Automatic timestamp and metadata inclusion
- Memory and file storage management
- Real-time log streaming

### 🐛 **Comprehensive Bug Reporting**
- Easy-to-use bug report creation
- Automatic device and app information collection
- Steps to reproduce tracking
- Severity classification
- Attachment support
- Tagging system for categorization

### 🚨 **Global Error Handling**
- Automatic Flutter error capture
- Platform error handling
- Zone-based error management
- Network error utilities
- Performance monitoring

### 📱 **Ready-to-Use UI Components**
- `BugReportForm` - Create bug reports with a beautiful UI
- `BugReportList` - View and manage bug reports
- Material Design integration
- Responsive design

### 📤 **Sharing & Export**
- Share bug reports via system share dialog
- Export logs and reports
- Multiple export formats
- Email integration ready

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  bugreport: ^0.0.1
```

Then run:
```bash
flutter pub get
```

## Quick Start

### 1. Initialize the System

```dart
import 'package:flutter/material.dart';
import 'package:bugreport/bugreport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize bug reporting system
  await BugReportSystem.initialize(
    loggerConfig: LoggerConfig(
      minLogLevel: LogLevel.debug,
      enableFileLogging: true,
      enableConsoleLogging: true,
    ),
    bugReportConfig: BugReportConfig(
      autoIncludeLogs: true,
      maxLogsPerReport: 100,
      defaultTags: ['my-app'],
    ),
    enableGlobalErrorHandling: true,
  );
  
  runApp(MyApp());
}
```

### 2. Use Logging

```dart
// Simple logging
BugReportSystem.debug('Debug message');
BugReportSystem.info('User logged in');
BugReportSystem.warning('Low memory warning');
BugReportSystem.error('Failed to load data');
BugReportSystem.fatal('Critical system error');

// Logging with metadata
BugReportSystem.info(
  'User action completed',
  tag: 'UserService',
  metadata: {
    'userId': 123,
    'action': 'purchase',
    'amount': 29.99,
  },
);
```

### 3. Error Reporting

```dart
try {
  // Some risky operation
  await riskyOperation();
} catch (e, stackTrace) {
  BugReportSystem.reportError(
    e,
    stackTrace: stackTrace,
    context: 'During user checkout',
    metadata: {
      'userId': currentUser.id,
      'cartItems': cart.items.length,
    },
  );
}
```

### 4. Network Error Handling

```dart
BugReportSystem.reportNetworkError(
  'Connection timeout',
  url: 'https://api.example.com/users',
  method: 'GET',
  statusCode: 408,
  requestData: {'page': 1, 'limit': 20},
);
```

### 5. Performance Monitoring

```dart
// Synchronous operations
final result = BugReportSystem.timeOperation(
  'Data Processing',
  () => processLargeDataset(),
  warningThreshold: Duration(seconds: 2),
);

// Asynchronous operations
final data = await BugReportSystem.timeAsyncOperation(
  'API Call',
  () => fetchUserData(),
  warningThreshold: Duration(milliseconds: 500),
);
```

### 6. Create Bug Reports Programmatically

```dart
final bugReport = await BugReportSystem.create(
  title: 'Login button not responding',
  description: 'When users tap the login button, nothing happens',
  severity: BugSeverity.high,
  stepsToReproduce: [
    'Open the app',
    'Navigate to login screen',
    'Enter valid credentials',
    'Tap login button',
  ],
  expectedBehavior: 'User should be logged in',
  actualBehavior: 'Nothing happens, button stays enabled',
  tags: ['login', 'ui', 'critical'],
  reportedBy: 'user@example.com',
);
```

## UI Components

### Bug Report Form

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BugReportForm(
      onReportCreated: (report) {
        Navigator.pop(context);
        // Handle successful creation
        showSuccessMessage('Bug report created: ${report.id}');
      },
    ),
  ),
);
```

### Bug Report List

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BugReportList(
      onReportSelected: (report) {
        // Handle report selection
        showReportDetails(report);
      },
    ),
  ),
);
```

## Advanced Configuration

### Logger Configuration

```dart
LoggerConfig(
  maxMemoryLogs: 1000,        // Max logs in memory
  maxFileLogs: 5000,          // Max logs in file
  minLogLevel: LogLevel.info, // Minimum level to log
  enableFileLogging: true,    // Write logs to file
  enableConsoleLogging: true, // Print to console
  logFileName: 'my_app.log',  // Custom log file name
  autoStackTrace: true,       // Auto-capture stack traces
)
```

### Bug Report Configuration

```dart
BugReportConfig(
  maxReports: 100,            // Max reports to store
  autoIncludeLogs: true,      // Include recent logs
  maxLogsPerReport: 50,       // Max logs per report
  defaultTags: ['prod'],      // Default tags
  autoCollectDeviceInfo: true, // Collect device info
)
```

## Error Handling Strategies

### Global Error Handling

```dart
// Automatic setup
await BugReportSystem.initialize(
  enableGlobalErrorHandling: true,
);

// Manual setup with custom handling
GlobalErrorHandler.initialize(
  captureFlutterErrors: true,
  capturePlatformErrors: true,
  tag: 'GlobalErrors',
);
```

### Zone-Based Error Handling

```dart
ZoneErrorHandler.runAppInZone(
  () => runApp(MyApp()),
  onError: (error, stack) {
    // Custom error handling logic
    sendToAnalytics(error, stack);
  },
);
```

## Sharing and Export

### Share Individual Reports

```dart
await BugReportSharer.shareBugReport(reportId);
```

### Share Multiple Reports

```dart
await BugReportSharer.shareMultipleReports([
  'report1_id',
  'report2_id',
  'report3_id',
]);
```

### Export Logs

```dart
await BugReportSharer.shareApplicationLogs();
```

### Share Statistics

```dart
await BugReportSharer.shareStatistics();
```

## API Reference

### Core Classes

- `BugReportSystem` - Main entry point for all functionality
- `BugReportLogger` - Advanced logging system
- `BugReportManager` - Bug report management
- `GlobalErrorHandler` - Global error capture
- `PerformanceMonitor` - Performance tracking

### Models

- `LogEntry` - Individual log record
- `BugReport` - Bug report data structure
- `DeviceInfo` - Device and app information
- `LogLevel` - Logging severity levels
- `BugSeverity` - Bug report severity levels

### Widgets

- `BugReportForm` - Bug report creation UI
- `BugReportList` - Bug report management UI

### Utilities

- `BugReportSharer` - Sharing functionality
- `ErrorReporter` - Manual error reporting
- `NetworkErrorHandler` - Network-specific errors
- `ZoneErrorHandler` - Zone-based error capture

## Best Practices

### 1. Initialize Early
Always initialize the bug report system in your `main()` function before calling `runApp()`.

### 2. Use Appropriate Log Levels
- `Debug`: Detailed information for debugging
- `Info`: General information about app flow
- `Warning`: Potential issues that don't break functionality
- `Error`: Errors that affect functionality but app continues
- `Fatal`: Critical errors that may crash the app

### 3. Include Context
Always provide meaningful context with your logs and error reports:

```dart
BugReportSystem.error(
  'Failed to save user data',
  tag: 'UserService',
  metadata: {
    'userId': user.id,
    'operation': 'save_profile',
    'timestamp': DateTime.now().toIso8601String(),
    'networkStatus': await connectivity.checkConnectivity(),
  },
);
```

### 4. Tag Consistently
Use consistent tagging to make filtering and searching easier:

```dart
// Good tagging examples
BugReportSystem.info('User logged in', tag: 'Authentication');
BugReportSystem.error('Payment failed', tag: 'Payment');
BugReportSystem.debug('Cache cleared', tag: 'DataService');
```

### 5. Monitor Performance
Use performance monitoring for critical operations:

```dart
// Monitor API calls
final response = await BugReportSystem.timeAsyncOperation(
  'User Profile Fetch',
  () => apiService.getUserProfile(userId),
  warningThreshold: Duration(seconds: 3),
  tag: 'API',
);

// Monitor heavy computations
final result = BugReportSystem.timeOperation(
  'Image Processing',
  () => processImage(imageData),
  warningThreshold: Duration(seconds: 1),
  tag: 'ImageProcessor',
);
```

### 6. Clean Up Resources
Don't forget to dispose of resources when your app shuts down:

```dart
@override
void dispose() {
  BugReportSystem.dispose();
  super.dispose();
}
```

## Example App

Check out the complete example app in the `example/` directory for a comprehensive demonstration of all features.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests, please file an issue on GitHub.
