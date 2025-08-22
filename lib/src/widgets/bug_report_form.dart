import 'package:flutter/material.dart';
import '../models/bug_report.dart';
import '../core/bug_report_manager.dart';
import '../utils/bug_report_sharer.dart';

/// A widget for creating new bug reports
class BugReportForm extends StatefulWidget {
  /// Callback when a bug report is created
  final void Function(BugReport report)? onReportCreated;
  
  /// Pre-filled title
  final String? initialTitle;
  
  /// Pre-filled description
  final String? initialDescription;
  
  /// Pre-filled steps
  final List<String>? initialSteps;

  const BugReportForm({
    super.key,
    this.onReportCreated,
    this.initialTitle,
    this.initialDescription,
    this.initialSteps,
  });

  @override
  State<BugReportForm> createState() => _BugReportFormState();
}

class _BugReportFormState extends State<BugReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _reporterController = TextEditingController();
  final _stepsControllers = <TextEditingController>[];
  final _tagsController = TextEditingController();
  
  BugSeverity _selectedSeverity = BugSeverity.medium;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    
    if (widget.initialSteps != null) {
      for (final step in widget.initialSteps!) {
        final controller = TextEditingController(text: step);
        _stepsControllers.add(controller);
      }
    }
    
    if (_stepsControllers.isEmpty) {
      _addStepField();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _reporterController.dispose();
    _tagsController.dispose();
    for (final controller in _stepsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStepField() {
    setState(() {
      _stepsControllers.add(TextEditingController());
    });
  }

  void _removeStepField(int index) {
    if (_stepsControllers.length > 1) {
      setState(() {
        _stepsControllers[index].dispose();
        _stepsControllers.removeAt(index);
      });
    }
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final steps = _stepsControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final bugReport = await BugReportManager.instance.createBugReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        stepsToReproduce: steps,
        expectedBehavior: _expectedController.text.trim().isEmpty 
            ? null 
            : _expectedController.text.trim(),
        actualBehavior: _actualController.text.trim().isEmpty 
            ? null 
            : _actualController.text.trim(),
        reportedBy: _reporterController.text.trim().isEmpty 
            ? null 
            : _reporterController.text.trim(),
        tags: tags,
      );

      widget.onReportCreated?.call(bugReport);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bug report created: ${bugReport.id}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _shareBugReport(bugReport.id),
            ),
          ),
        );
        
        // Clear form
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create bug report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _expectedController.clear();
    _actualController.clear();
    _reporterController.clear();
    _tagsController.clear();
    
    for (final controller in _stepsControllers) {
      controller.dispose();
    }
    _stepsControllers.clear();
    _addStepField();
    
    setState(() {
      _selectedSeverity = BugSeverity.medium;
    });
  }

  Future<void> _shareBugReport(String reportId) async {
    try {
      await BugReportSharer.shareBugReport(reportId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bug Report'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _clearForm,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bug Title *',
                hintText: 'Brief description of the bug',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Detailed description of the issue',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Severity
            DropdownButtonFormField<BugSeverity>(
              value: _selectedSeverity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: BugSeverity.values.map((severity) {
                return DropdownMenuItem(
                  value: severity,
                  child: Row(
                    children: [
                      Icon(
                        _getSeverityIcon(severity),
                        color: _getSeverityColor(severity),
                      ),
                      const SizedBox(width: 8),
                      Text(severity.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSeverity = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Steps to reproduce
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Steps to Reproduce',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _addStepField,
                          icon: const Icon(Icons.add),
                          tooltip: 'Add step',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._stepsControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Step ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                validator: (value) {
                                  if (index == 0 && (value == null || value.trim().isEmpty)) {
                                    return 'Please enter at least one step';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (_stepsControllers.length > 1)
                              IconButton(
                                onPressed: () => _removeStepField(index),
                                icon: const Icon(Icons.remove),
                                tooltip: 'Remove step',
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Expected behavior
            TextFormField(
              controller: _expectedController,
              decoration: const InputDecoration(
                labelText: 'Expected Behavior',
                hintText: 'What should happen?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Actual behavior
            TextFormField(
              controller: _actualController,
              decoration: const InputDecoration(
                labelText: 'Actual Behavior',
                hintText: 'What actually happens?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Reporter
            TextFormField(
              controller: _reporterController,
              decoration: const InputDecoration(
                labelText: 'Reporter',
                hintText: 'Your name or identifier',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Comma-separated tags (e.g., ui, login, crash)',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBugReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Creating...'),
                      ],
                    )
                  : const Text(
                      'Create Bug Report',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
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
