import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bug_report.dart';
import '../core/bug_report_manager.dart';
import '../utils/bug_report_sharer.dart';
import 'bug_report_form.dart';

/// A widget for listing and managing bug reports
class BugReportList extends StatefulWidget {
  /// Callback when a bug report is selected
  final void Function(BugReport report)? onReportSelected;
  
  /// Whether to show floating action button for creating reports
  final bool showCreateButton;
  
  /// Custom app bar title
  final String? title;

  const BugReportList({
    super.key,
    this.onReportSelected,
    this.showCreateButton = true,
    this.title,
  });

  @override
  State<BugReportList> createState() => _BugReportListState();
}

class _BugReportListState extends State<BugReportList> {
  List<BugReport> _reports = [];
  List<BugReport> _filteredReports = [];
  String _searchQuery = '';
  BugSeverity? _severityFilter;
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
    
    // Listen to new reports
    BugReportManager.instance.reportStream.listen((report) {
      if (mounted) {
        _loadReports();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await BugReportManager.instance.initialize();
      final reports = BugReportManager.instance.reports;
      
      setState(() {
        _reports = reports;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bug reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredReports = _reports.where((report) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!report.title.toLowerCase().contains(query) &&
            !report.description.toLowerCase().contains(query) &&
            !report.id.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Severity filter
      if (_severityFilter != null && report.severity != _severityFilter) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onSeverityFilterChanged(BugSeverity? severity) {
    setState(() {
      _severityFilter = severity;
      _applyFilters();
    });
  }

  Future<void> _deleteBugReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bug Report'),
        content: const Text('Are you sure you want to delete this bug report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BugReportManager.instance.deleteBugReport(id);
        _loadReports();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bug report deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete bug report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareReport(String id) async {
    try {
      await BugReportSharer.shareBugReport(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share bug report: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _createBugReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BugReportForm(
          onReportCreated: (report) {
            Navigator.of(context).pop();
            _loadReports();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Bug Reports'),
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_all',
                child: Text('Export All'),
              ),
              const PopupMenuItem(
                value: 'share_all',
                child: Text('Share All'),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Text('Statistics'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All'),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bug reports...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
                
                const SizedBox(height: 8),
                
                // Severity filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _severityFilter == null,
                        onSelected: (_) => _onSeverityFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      ...BugSeverity.values.map((severity) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(severity.name),
                            selected: _severityFilter == severity,
                            onSelected: (_) => _onSeverityFilterChanged(severity),
                            avatar: Icon(
                              _getSeverityIcon(severity),
                              size: 16,
                              color: _getSeverityColor(severity),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredReports.length} of ${_reports.length} reports',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Bug reports list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = _filteredReports[index];
                          return _buildReportCard(report);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.showCreateButton
          ? FloatingActionButton(
              onPressed: _createBugReport,
              tooltip: 'Create Bug Report',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bug_report,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _reports.isEmpty 
                ? 'No bug reports yet'
                : 'No reports match your filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _reports.isEmpty
                ? 'Create your first bug report'
                : 'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (widget.showCreateButton && _reports.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createBugReport,
              icon: const Icon(Icons.add),
              label: const Text('Create Bug Report'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportCard(BugReport report) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getSeverityIcon(report.severity),
                  size: 16,
                  color: _getSeverityColor(report.severity),
                ),
                const SizedBox(width: 4),
                Text(
                  report.severity.name,
                  style: TextStyle(
                    color: _getSeverityColor(report.severity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(report.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (report.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: report.tags.take(3).map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Text('Share'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) => _handleReportAction(value, report),
        ),
        onTap: () => widget.onReportSelected?.call(report),
      ),
    );
  }

  void _handleReportAction(String action, BugReport report) {
    switch (action) {
      case 'view':
        widget.onReportSelected?.call(report);
        break;
      case 'share':
        _shareReport(report.id);
        break;
      case 'delete':
        _deleteBugReport(report.id);
        break;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_all':
        _exportAllReports();
        break;
      case 'share_all':
        _shareAllReports();
        break;
      case 'statistics':
        _showStatistics();
        break;
      case 'clear_all':
        _clearAllReports();
        break;
    }
  }

  Future<void> _exportAllReports() async {
    try {
      await BugReportSharer.shareAllReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export reports: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _shareAllReports() async {
    try {
      await BugReportSharer.shareAllReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share reports: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showStatistics() {
    final stats = BugReportManager.instance.getStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bug Report Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Reports: ${stats['totalReports']}'),
            Text('Recent (7 days): ${stats['recentReports']}'),
            const SizedBox(height: 16),
            const Text('By Severity:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...((stats['bySeverity'] as Map<String, int>).entries.map((entry) {
              return Text('${entry.key}: ${entry.value}');
            })),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              BugReportSharer.shareStatistics();
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllReports() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Reports'),
        content: const Text('Are you sure you want to delete all bug reports? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BugReportManager.instance.clearAllReports();
        _loadReports();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All bug reports cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear reports: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getSeverityIcon(BugSeverity severity) {
    switch (severity) {
      case BugSeverity.low:
        return Icons.info;
      case BugSeverity.medium:
        return Icons.warning;
      case BugSeverity.high:
        return Icons.error;
      case BugSeverity.critical:
        return Icons.dangerous;
    }
  }

  Color _getSeverityColor(BugSeverity severity) {
    switch (severity) {
      case BugSeverity.low:
        return Colors.blue;
      case BugSeverity.medium:
        return Colors.orange;
      case BugSeverity.high:
        return Colors.red;
      case BugSeverity.critical:
        return Colors.purple;
    }
  }
}
