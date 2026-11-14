import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../models/student.dart';
import '../../services/app_services.dart';
import '../../widgets/common.dart';
import '../shared/file_saved_screen.dart';

/// Faculty / Summary Page (Week 3): shown after Add Student. The form
/// passes the data through this constructor; Save to File writes
/// student_record.txt and student_info.txt, then shows File Saved.
class StudentSummaryScreen extends StatefulWidget {
  const StudentSummaryScreen({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.email,
    required this.program,
    required this.yearLevel,
    this.contactNumber = '',
    this.address = '',
  });

  final String studentName;
  final String studentId;
  final String email;
  final String program;
  final String yearLevel;
  final String contactNumber;
  final String address;

  @override
  State<StudentSummaryScreen> createState() => _StudentSummaryScreenState();
}

class _StudentSummaryScreenState extends State<StudentSummaryScreen> {
  bool _saving = false;

  Student get _student => Student(
    id: widget.studentId,
    name: widget.studentName,
    email: widget.email,
    program: widget.program,
    yearLevel: widget.yearLevel,
    grade: 0,
    contact: widget.contactNumber,
    address: widget.address,
  );

  Future<void> _saveToFile() async {
    final services = AppScope.of(context);
    setState(() => _saving = true);
    try {
      final record = await services.files.saveRecord(_student);
      final info = await services.files.exportStudent(_student);
      await services.activity.add(
        ActivityKind.export,
        'Record exported',
        '${widget.studentName} · ${info.fileName}',
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FileSavedScreen(result: info, alsoSaved: [record.fileName]),
        ),
      );
      // Done on File Saved goes back to the directory.
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (mounted) {
        showAppSnack(context, 'Could not save the file: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      (Icons.person, 'Student Name', widget.studentName),
      (Icons.badge, 'Student ID', widget.studentId),
      (Icons.email, 'Email Address', widget.email),
      (
        Icons.school,
        'Program',
        Student.programNames[widget.program] ?? widget.program,
      ),
      (Icons.calendar_today, 'Year Level', widget.yearLevel),
      (
        Icons.phone,
        'Contact Number',
        widget.contactNumber.isEmpty ? '—' : widget.contactNumber,
      ),
      (Icons.home, 'Address', widget.address.isEmpty ? '—' : widget.address),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Student saved. Review the details below.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            for (final (icon, label, value) in fields) ...[
              Card(
                child: ListTile(
                  leading: Icon(icon, color: Colors.black),
                  title: Text(label),
                  subtitle: Text(value),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              key: const Key('summary.save'),
              onPressed: _saving ? null : _saveToFile,
              icon: const Icon(Icons.save),
              label: const Text('Save to File'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Student Directory'),
            ),
          ],
        ),
      ),
    );
  }
}
