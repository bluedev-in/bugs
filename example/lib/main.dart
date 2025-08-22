import 'package:flutter/material.dart';
import 'package:bugs/bugs.dart';

/// Example application demonstrating the bug report system
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
      defaultTags: ['example-app'],
    ),
    enableGlobalErrorHandling: true,
  );
  
  // Run the app in an error-capturing zone
  ZoneErrorHandler.runAppInZone(
    () => runApp(const BugReportExampleApp()),
  );
}

class BugReportExampleApp extends StatelessWidget {
  const BugReportExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bug Report Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    
    // Log app start
    BugReportSystem.info(
      'App started successfully',
      tag: 'HomePage',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'page': 'HomePage',
      },
    );
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    
    // Log the action
    BugReportSystem.debug(
      'Counter incremented',
      tag: 'HomePage',
      metadata: {
        'oldValue': _counter - 1,
        'newValue': _counter,
      },
    );
  }

  void _simulateError() {
    try {
      // Simulate an error
      throw Exception('This is a simulated error for testing');
    } catch (e, stackTrace) {
      BugReportSystem.reportError(
        e,
        stackTrace: stackTrace,
        context: 'User triggered error simulation',
        metadata: {
          'counter': _counter,
          'timestamp': DateTime.now().toIso8601String(),
        },
        tag: 'HomePage',
      );
      
      // Show user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error simulated and logged!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _simulateNetworkError() {
    BugReportSystem.reportNetworkError(
      'Connection timeout',
      url: 'https://api.example.com/data',
      method: 'GET',
      statusCode: 408,
      requestData: {'userId': 123},
      tag: 'NetworkService',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error logged!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performSlowOperation() {
    BugReportSystem.timeOperation(
      'Slow Operation',
      () {
        // Simulate slow operation
        for (int i = 0; i < 1000000; i++) {
          // Busy work
        }
        return 'Operation completed';
      },
      warningThreshold: const Duration(milliseconds: 100),
      tag: 'Performance',
      metadata: {
        'counter': _counter,
      },
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slow operation completed and timed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openBugReportForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BugReportForm(
          initialTitle: 'Issue with counter functionality',
          initialDescription: 'The counter seems to behave unexpectedly when...',
          initialSteps: [
            'Open the app',
            'Click the increment button',
            'Observe the counter value',
          ],
          onReportCreated: (report) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bug report created: ${report.id}'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _viewBugReports() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BugReportList(
          onReportSelected: (report) {
            _showBugReportDetails(report);
          },
        ),
      ),
    );
  }

  void _showBugReportDetails(BugReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Text(report.toFormattedString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              BugReportSharer.shareBugReport(report.id);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Bug Report Example'),
        actions: [
          IconButton(
            onPressed: _viewBugReports,
            icon: const Icon(Icons.bug_report),
            tooltip: 'View Bug Reports',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            
            // Testing buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _simulateError,
                  icon: const Icon(Icons.error),
                  label: const Text('Simulate Error'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _simulateNetworkError,
                  icon: const Icon(Icons.wifi_off),
                  label: const Text('Network Error'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _performSlowOperation,
                  icon: const Icon(Icons.speed),
                  label: const Text('Slow Operation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openBugReportForm,
                  icon: const Icon(Icons.report_problem),
                  label: const Text('Create Bug Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Statistics
            FutureBuilder<Map<String, dynamic>>(
              future: Future.value(BugReportSystem.getStatistics()),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bug Report Statistics',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Total Reports: ${stats['totalReports']}'),
                          Text('Recent Reports: ${stats['recentReports']}'),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
